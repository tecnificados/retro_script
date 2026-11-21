import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.regex.*;

/**
 * Construye el inventario de recursos remotos a partir de los scripts PowerShell y de los catálogos CSV que referencian. Conserva el origen de cada enlace para localizarlo en un informe de fallos.
 */
final class Inventory {
    /**
     * Selecciona qué contenido debe devolver el servidor: archivo ZIP, imagen, ficha con descripción, página HTML, traducción o recurso genérico.
     */
    enum Kind { ZIP, IMAGE, METADATA, HTML, TRANSLATION, RESOURCE }
    /**
     * Describe una comprobación y permite rastrear el enlace hasta el proyecto.
     * @param kind validación que se aplicará a la respuesta
     * @param uri dirección que se consultará
     * @param source archivo y línea del script, o catálogo e identificador del juego
     * @param discoverImage indica si debe extraerse de la ficha una imagen para comprobarla después
     */
    record Check(Kind kind, URI uri, String source, boolean discoverImage) {}
    static final String SAMPLE = "The game is ready.";
    private static final Pattern ASSIGN = Pattern.compile("^\\s*\\$(\\w+)\\s*=\\s*(['\"])(.*?)\\2\\s*(?:#.*)?$");
    private static final Pattern URL = Pattern.compile("(['\"])(https?://.*?)\\1", Pattern.CASE_INSENSITIVE);
    private static final Pattern VARIABLE = Pattern.compile("\\$\\{(\\w+)}|\\$(\\w+)");
    private static final Pattern CSV = Pattern.compile("(?i)Join-Path\\s+\\$(?:Root|PSScriptRoot)\\s+(['\"])([^'\"]+\\.csv)\\1");

    /**
     * Enumera mediante Git los scripts versionados y los nuevos que no estén ignorados. Procesa los scripts y después lee una sola vez cada catálogo referenciado.
     * @param root raíz del repositorio
     * @return comprobaciones en orden de descubrimiento, incluidas las referencias repetidas a una URL
     * @throws Exception si Git falla, se interrumpe la espera, una fuente no se puede procesar o el inventario queda vacío
     */
    static List<Check> discover(Path root) throws Exception {
        var git = new ProcessBuilder("git", "ls-files", "-z", "--cached", "--others",
                "--exclude-standard", "--", "*.ps1").directory(root.toFile()).redirectError(ProcessBuilder.Redirect.INHERIT).start();
        String paths = new String(git.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        if (git.waitFor() != 0) throw new IOException("No se pudieron enumerar los scripts del repositorio.");
        var checks = new ArrayList<Check>();
        var catalogs = new LinkedHashSet<Path>();
        for (String path : paths.split("\0")) {
            if (!path.isBlank()) readScript(root, Path.of(path), checks, catalogs);
        }
        for (Path catalog : catalogs) readCatalog(root, catalog, checks);
        if (checks.isEmpty()) throw new IOException("No se encontraron URL en los scripts.");
        return checks;
    }

    /**
     * Lee el script línea a línea sin ejecutar PowerShell. En URL entre comillas dobles sustituye variables a partir de asignaciones simples anteriores. Para la consulta de traducción utiliza {@link #SAMPLE} como texto de prueba.
     * @param root raíz del repositorio
     * @param path ruta del script relativa a la raíz
     * @param checks lista a la que se añaden los enlaces con su línea de origen
     * @param catalogs conjunto al que se añaden los CSV identificados mediante {@code Join-Path}
     * @throws IOException si falla la lectura o se encuentra una variable de URL sin resolver
     */
    static void readScript(Path root, Path path, List<Check> checks, Set<Path> catalogs) throws IOException {
        var values = new TreeMap<String, String>(String.CASE_INSENSITIVE_ORDER);
        var lines = Files.readAllLines(root.resolve(path));
        boolean comment = false;
        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i).replace("\uFEFF", "").strip();
            if (line.startsWith("<#")) comment = true;
            if (comment) {
                if (line.contains("#>")) comment = false;
                continue;
            }
            if (line.startsWith("#")) continue;
            String source = path + ":" + (i + 1);
            Matcher assignment = ASSIGN.matcher(line);
            if (assignment.matches()) values.put(assignment.group(1), assignment.group(3));
            Matcher csv = CSV.matcher(line);
            while (csv.find()) catalogs.add(path.resolveSibling(csv.group(2)));
            Matcher urls = URL.matcher(line);
            while (urls.find()) {
                String url = urls.group(2);
                boolean translation = line.contains("Invoke-RestMethod") && url.contains("langpair=");
                if (urls.group(1).equals("\"")) {
                    Matcher vars = VARIABLE.matcher(url);
                    StringBuilder expanded = new StringBuilder();
                    while (vars.find()) {
                        String name = vars.group(1) == null ? vars.group(2) : vars.group(1);
                        String value = translation && name.equalsIgnoreCase("query")
                                ? java.net.URLEncoder.encode(SAMPLE, StandardCharsets.UTF_8) : values.get(name);
                        if (value == null) throw new IOException(source + " — variable sin resolver: $" + name);
                        vars.appendReplacement(expanded, Matcher.quoteReplacement(value));
                    }
                    url = vars.appendTail(expanded).toString();
                }
                URI uri = URI.create(url);
                Kind kind = translation ? Kind.TRANSLATION :
                        (uri.getPath().toLowerCase(Locale.ROOT).endsWith(".zip") ? Kind.ZIP : Kind.RESOURCE);
                checks.add(new Check(kind, uri, source, false));
            }
        }
    }

    /**
     * Clasifica las columnas cuyo nombre termina en {@code Url}. Las fichas de ScummVM requieren HTML; las demás fichas requieren una descripción y, cuando falta {@code ImageUrl}, una imagen extraída de la página.
     * @param root raíz del repositorio
     * @param path ruta relativa del catálogo UTF-8
     * @param checks lista a la que se añaden las comprobaciones de las celdas con URL
     * @throws IOException si falla la lectura, falta la cabecera o el CSV tiene comillas o filas incompletas
     */
    static void readCatalog(Path root, Path path, List<Check> checks) throws IOException {
        // Los CSV del instalador usan punto y coma y comillas dobles escapadas por duplicación.
        var rows = csvRows(Files.readString(root.resolve(path)).replaceFirst("^\\uFEFF", ""));
        if (rows.isEmpty()) throw new IOException(path + " — CSV sin cabecera.");
        var header = rows.removeFirst();
        for (var row : rows) {
            if (row.size() != header.size()) throw new IOException(path + " — fila incompleta: " + row);
            var fields = new TreeMap<String,String>(String.CASE_INSENSITIVE_ORDER);
            for (int i = 0; i < header.size(); i++) fields.put(header.get(i), row.get(i).strip());
            String source = path + " · " + fields.getOrDefault("GameFile", fields.getOrDefault("Title", ""));
            for (var field : fields.entrySet()) {
                if (!field.getKey().toLowerCase(Locale.ROOT).endsWith("url") || field.getValue().isBlank()) continue;
                Kind kind = switch (field.getKey().toLowerCase(Locale.ROOT)) {
                    case "downloadurl" -> Kind.ZIP;
                    case "imageurl" -> Kind.IMAGE;
                    case "sourceurl" -> "scummvm".equalsIgnoreCase(fields.get("System")) ? Kind.HTML : Kind.METADATA;
                    default -> Kind.RESOURCE;
                };
                checks.add(new Check(kind, URI.create(field.getValue()), source,
                        kind == Kind.METADATA && fields.getOrDefault("ImageUrl", "").isBlank()));
            }
        }
    }

    /**
     * Separa campos por punto y coma. Dentro de un campo entrecomillado conserva separadores y saltos de línea, e interpreta las comillas duplicadas como una comilla literal.
     * @param text contenido del catálogo
     * @return filas no vacías en orden de lectura, incluida la cabecera si existe
     * @throws IOException si queda un campo entrecomillado sin cerrar
     */
    static List<List<String>> csvRows(String text) throws IOException {
        var rows = new ArrayList<List<String>>();
        List<String> row = new ArrayList<>();
        var field = new StringBuilder();
        boolean quoted = false;
        for (int i = 0; i <= text.length(); i++) {
            char c = i == text.length() ? '\n' : text.charAt(i);
            if (c == '"') {
                if (quoted && i + 1 < text.length() && text.charAt(i + 1) == '"') {
                    field.append('"');
                    i++;
                } else quoted = !quoted;
            } else if (!quoted && (c == ';' || c == '\n' || c == '\r')) {
                row.add(field.toString());
                field.setLength(0);
                if (c != ';') {
                    if (row.size() > 1 || !row.getFirst().isBlank()) rows.add(row);
                    row = new ArrayList<>();
                    if (c == '\r' && i + 1 < text.length() && text.charAt(i + 1) == '\n') i++;
                }
            } else field.append(c);
        }
        if (quoted) throw new IOException("Comillas sin cerrar en el CSV.");
        return rows;
    }
}
