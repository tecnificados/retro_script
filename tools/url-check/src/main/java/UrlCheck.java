import com.google.gson.JsonParser;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.IOException;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;

/**
 * Verificador de recursos remotos de Retro Script. Lee las comprobaciones de {@link Inventory}, valida las respuestas según su contenido y produce el resumen que utiliza GitHub Actions.
 */
public final class UrlCheck {
    /**
     * Ejecuta el monitor desde la raíz del repositorio. Reintenta una vez cada comprobación fallida tras dos segundos y añade a la cola las imágenes descubiertas en las fichas. Al terminar escribe el resumen antes de señalar los fallos persistentes.
     * @param args {@code --list} para mostrar el inventario sin solicitudes HTTP, o {@code --report ruta} para guardar el resumen de la ejecución
     * @throws Exception si falla el descubrimiento, se interrumpe la ejecución, no se puede escribir el informe o queda alguna comprobación fallida
     */
    public static void main(String[] args) throws Exception {
        boolean list = false;
        Path report = null;
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--list" -> list = true;
                case "--report" -> report = Path.of(args[++i]);
                default -> throw new IllegalArgumentException("Opción desconocida: " + args[i]);
            }
        }
        var queue = new ArrayList<>(Inventory.discover(Path.of("").toAbsolutePath()));
        if (list) {
            queue.forEach(check -> System.out.println(describe(check)));
            System.out.println("Comprobaciones: " + queue.size());
            return;
        }
        var failures = new ArrayList<String>();
        for (int index = 0; index < queue.size(); index++) {
            var check = queue.get(index);
            for (int attempt = 1; attempt <= 2; attempt++) {
                try {
                    URI image = probe(check);
                    if (image != null) queue.add(new Inventory.Check(Inventory.Kind.IMAGE, image, check.source(), false));
                    System.out.println("OK " + describe(check));
                    break;
                } catch (Exception error) {
                    if (attempt == 1) {
                        Thread.sleep(2000);
                    } else {
                        String failure = describe(check) + " — " + error;
                        failures.add("- " + failure);
                        System.err.println(failure);
                    }
                }
            }
        }
        String summary = "Comprobaciones correctas: " + (queue.size() - failures.size())
                + ". Fallidas: " + failures.size() + ".\n\n" + String.join("\n", failures) + "\n";
        System.out.print(summary);
        if (report != null) Files.writeString(report, summary);
        if (!failures.isEmpty()) throw new IOException("Fallos en " + failures.size() + " comprobaciones.");
    }

    /**
     * Identifica el recurso en la salida de consola y en el informe.
     * @param check comprobación que se va a mostrar
     * @return tipo, origen y URI del recurso
     */
    private static String describe(Inventory.Check check) {
        return check.kind() + " · " + check.source() + " · " + check.uri();
    }

    /**
     * Realiza un intento HTTP y exige una respuesta 2xx. Para ZIP e imágenes lee hasta 12 bytes; para recursos genéricos comprueba que haya contenido. Limita a 4 MiB las respuestas HTML y JSON.
     * @param check recurso y validación que se debe aplicar
     * @return URI de una imagen descubierta en la ficha, o {@code null} si no hay que ampliar la cola
     * @throws IOException si falla la conexión, el estado HTTP o la validación del contenido
     */
    static URI probe(Inventory.Check check) throws IOException {
        HttpURLConnection connection = (HttpURLConnection) check.uri().toURL().openConnection();
        connection.setConnectTimeout(15000);
        connection.setReadTimeout(30000);
        connection.setRequestProperty("User-Agent", "RetroScript-UrlCheck/1.0");
        boolean binary = check.kind() == Inventory.Kind.ZIP || check.kind() == Inventory.Kind.IMAGE;
        if (binary) connection.setRequestProperty("Range", "bytes=0-11");
        try {
            int status = connection.getResponseCode();
            if (status < 200 || status >= 300) throw new IOException("HTTP " + status);
            try (var stream = connection.getInputStream()) {
                if (binary) {
                    validatePrefix(check.kind(), stream.readNBytes(12));
                } else if (check.kind() == Inventory.Kind.RESOURCE) {
                    if (stream.read() < 0) throw new IOException("Respuesta vacía");
                } else {
                    int limit = 4 * 1024 * 1024;
                    byte[] bytes = stream.readNBytes(limit + 1);
                    if (bytes.length > limit) throw new IOException("La respuesta supera 4 MiB");
                    String body = new String(bytes, StandardCharsets.UTF_8);
                    if (check.kind() == Inventory.Kind.TRANSLATION) validateTranslation(body);
                    else return validatePage(check, body);
                }
            }
        } finally {
            connection.disconnect();
        }
        return null;
    }

    /**
     * Reconoce la cabecera de archivo local ZIP o las firmas de JPEG, PNG, GIF y WebP. Esta prueba solo examina el comienzo del archivo.
     * @param kind tipo binario esperado, {@code ZIP} o {@code IMAGE}
     * @param bytes primeros bytes recibidos del servidor
     * @throws IOException si la firma no corresponde al tipo esperado
     */
    static void validatePrefix(Inventory.Kind kind, byte[] bytes) throws IOException {
        String signature = HexFormat.of().formatHex(bytes);
        boolean valid = kind == Inventory.Kind.ZIP ? signature.startsWith("504b0304")
                : signature.matches("^(ffd8ff|89504e470d0a1a0a|474946383[79]61|52494646.{8}57454250).*");
        if (!valid) throw new IOException("Cabecera incompatible con " + kind);
    }

    /**
     * Comprueba el estado que MyMemory declara dentro del JSON y que el texto traducido tenga contenido y difiera de {@link Inventory#SAMPLE}.
     * @param body cuerpo JSON de la respuesta de MyMemory
     * @throws IOException si el servicio indica un fallo o devuelve una traducción vacía o idéntica al original
     */
    static void validateTranslation(String body) throws IOException {
        var json = JsonParser.parseString(body).getAsJsonObject();
        if (json.get("responseStatus").getAsInt() != 200) throw new IOException("MyMemory: " + json.get("responseDetails"));
        String text = json.getAsJsonObject("responseData").get("translatedText").getAsString().strip();
        if (text.isEmpty() || text.equals(Inventory.SAMPLE)) throw new IOException("MyMemory no devolvió una traducción");
    }

    /**
     * Comprueba que la página tenga título o metadatos. Para una ficha de metadatos exige además una descripción en etiquetas meta o en {@code reviewBody}. Cuando el catálogo delega la imagen en la ficha, resuelve su dirección respecto de la URI comprobada.
     * @param check comprobación de tipo HTML o METADATA
     * @param html contenido recibido de la página
     * @return URI de la imagen que debe verificarse, o {@code null} si la ficha no requiere descubrirla
     * @throws IOException si falta alguno de los datos requeridos
     */
    static URI validatePage(Inventory.Check check, String html) throws IOException {
        Document doc = Jsoup.parse(html, check.uri().toString());
        if (doc.title().isBlank() && doc.selectFirst("meta[content]") == null) throw new IOException("Ficha HTML sin título ni metadatos");
        if (check.kind() == Inventory.Kind.HTML) return null;
        String description = meta(doc, Set.of("og:description", "description", "twitter:description"));
        if (description.isBlank() && !html.matches("(?s).*\"reviewBody\"\\s*:\\s*\"[^\"\\s].*"))
            throw new IOException("Ficha sin descripción");
        if (!check.discoverImage()) return null;
        String image = meta(doc, Set.of("og:image", "twitter:image"));
        if (image.isBlank()) throw new IOException("Ficha sin imagen");
        return check.uri().resolve(image);
    }

    /**
     * Busca en orden de aparición las etiquetas meta cuyos atributos {@code name} o {@code property} coinciden con uno de los nombres indicados.
     * @param doc página HTML analizada
     * @param names nombres de metadatos aceptados, en minúsculas
     * @return contenido de la primera coincidencia sin espacios exteriores, o una cadena vacía si no hay coincidencias
     */
    private static String meta(Document doc, Set<String> names) {
        for (var tag : doc.select("meta[content]")) {
            if (names.contains(tag.attr("name").toLowerCase(Locale.ROOT))
                    || names.contains(tag.attr("property").toLowerCase(Locale.ROOT))) return tag.attr("content").strip();
        }
        return "";
    }
}
