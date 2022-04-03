#!/bin/rdmd

//enum mailPath = "/tmp/foo";
enum mailPath="/home/dcg/Correo/.linux-kernel.directory/.commits.directory/commitlist/new/";
enum codeRepo="/home/dcg/código/linux";
enum gitRepo = codeRepo ~ "/.git";


import std.stdio : writeln;
void main() {
    import std.array : array, byPair, assocArray;
    import std.algorithm : map;
    import std.range : chain;

//    writeln("CommitMails");
    Mail[string] mails = parseMails(mailPath);

//    writeln("Maintainers");
    Subsys maint = parseMaintainers(codeRepo ~ "/MAINTAINERS").filterMaintainers(['F']);
    Subsys uapi; uapi["uapi"] = [Entry('F', "include/uapi")];
    maint = maint.byPair.chain(uapi.byPair).assocArray;

    string lista = generaLista(mails, maint);
    writeln("Lista final\n", lista);
}

struct Diferencia {
    string añadidas;
    string borradas;
    string ruta;
}
struct Mail {
    string subject; // Mail subject
    Diferencia[] diferencias;
}

Mail[string] parseMails(string path) {
    import std.array : array;
    import std.file : DirEntry, dirEntries, SpanMode, isFile;
    import std.algorithm : filter;

    Mail[string] ret;

    DirEntry[] files = dirEntries(path, SpanMode.depth)
        .filter!(a => a.isFile)
        .array;

    foreach(file; files) {
        import std.file : readText;
        import std.regex : matchFirst, regex, Regex, Captures;
        import std.process : execute, Config;
        import std.conv : to;
        import std.string : splitLines;
        import std.stdio : writeln;

        string buf = readText(file);
        if (buf == "") {
            writeln("WARNING: Empty mail " ~ file);
            continue;
        }
        Regex!char expr = regex(`X-Git-Rev: (?P<id>[A-Fa-f0-9]{40})`);
        Captures!string match = matchFirst(buf, expr);
        assert(match.empty == 0, "File didn't contain X-Git-Rev field: " ~ file);
        string commit = match["id"];

        auto diffStat = execute([`git`, `--git-dir=` ~ gitRepo, `show`, `--pretty=format:%s`, `--numstat`, commit], null, Config.none, ulong.max, gitRepo);
        assert(diffStat.status == 0, "Git show failed: " ~ diffStat.to!string ~ ". Perhaps git pull needed?");

        Mail email;
        email.subject = diffStat.output.splitLines[0];
        email.diferencias = ordenaDiferencias(diffStat.output.splitLines[1..$]);
        ret[commit] = email;
    }
    return ret;
}
// Se prioriza la diferencia con mayor cantidad de cambios
// Cada diferencia es el nombre de archivo y el número de + y -
// Ordenadas por número de cambios
Diferencia[] ordenaDiferencias(string[] diffs) {
    import std.algorithm : sort, any, filter, map;
    import std.range : array;
    import std.conv : to;

    // string[][]
    auto pre = diffs.map!((diff) {
        import std.regex : matchFirst, regex, Regex, Captures;

        Regex!char expr = regex(`(?P<add>\S+)\t(?P<del>\S+)\t(?P<file>.*)`);
        Captures!string match = matchFirst(diff, expr);
        assert(match.empty == 0, "Error parsing diffstat: " ~ diff);

        return [match["add"], match["del"], match["file"]];
    });

    Diferencia[] regs = pre
        .filter!(dif => dif.any!(campo => campo != "-"))
        .array
        .sort!((a, b) => a[0].to!int > b[0].to!int)
        .map!(i => Diferencia(i[0], i[1], i[2]))
        .array;

    return regs;
}


struct Entry {
    char type; // F
    string expr; // regex
}
alias Subsys = Entry[][string]; // Indexed by subsystem name, contains several entries per subsys
   
Subsys parseMaintainers(string path) {
    import std.stdio : File;

    Subsys ret;

    auto buf = File(path);
    string title = "";
    /*
     * The maintainers file does not have any formal format
     * We detect the "title" by waiting for a newline, then we set the title variable to the next line
     * After a void line the title is resetted again
     */
    foreach(line; buf.byLine) {
        import std.regex : regex, matchFirst;
        import std.conv : to;
        import std.array : split;
 
        if (line == "") {
            title = "";
            continue;
        }

        if (title == "") {
            title = line.to!string;
            continue;
        }

        auto expr = regex(`^([A-Z]):\s*(.*)`);
        auto match = matchFirst(line, expr);

        Entry[] fill;

        if (match.empty == false) {
            import std.conv : to;

            string[] res = split(match.hit.to!string, "\t");
            // Some entries use whitespaces instead of tabs
            if (res.length != 2)
                continue;

            Entry tmp;
            // M:<tab>blah
            tmp.type = line[0];
            tmp.expr= line[3..$].to!string;
            fill ~= tmp;
        }
        ret[title] ~= fill;
    }
    return ret;
}


Subsys filterMaintainers(Subsys maint, char[] keys) {
    import std.algorithm : filter, any;
    import std.array : array;

    Subsys ret;
    foreach(sub, ent; maint) {
        Entry[] fill;
        fill = ent.filter!(item => keys.any!(k => k == item.type)).array;
        if (fill.length > 0)
            ret[sub] = fill;
    }
    return ret;
}



struct Correlación {
    Mail mail;
    string commit;
    string subsys;
    string subsysRuta;
}
// Primero, se busca entre las expresiones de cada entrada de mantenedores la que tiene 
// mayor cantidad de barras (más específica). Luego, de entre todas esas, también la que
// tiene la mayor cantidad de barras

string generaLista(Mail[string] mails, Subsys sub) {
    import std.algorithm : map, sort, uniq, filter, each;
    import std.range : array, repeat, join;
    import std.array : Appender, appender, byPair;
foreach(mail; mails) writeln("Mail: ", mail);
    auto asociaciones = [
        "Core": ["kernel"],
        "File systems": ["fs"],
        "Memory management": ["mm"],
        "Networking": ["net", "drivers/net", "include/net"],
        "Graphics": ["drivers/gpu"],
        "Security": ["security"],
        "Virtualization": ["virt"],
        "Architectures": ["arch"],
    ];

    bool estáAsociado(Diferencia[] difes, string[] rutas) {
        import std.algorithm : startsWith;
        foreach(ruta; rutas) {
            foreach(dif; difes) {
                if (dif.ruta.startsWith(ruta)) return true;
            }
        }
        return false;
    }

    Subsys sacarEntradas(Subsys lista, string[] rutas) {
        Subsys ret;
        foreach(nombre, entradas; lista.byPair) {
            foreach(ruta; rutas) {
                foreach(entrada; entradas) {
                    import std.algorithm : startsWith;
                    if (entrada.expr.startsWith(ruta)) {
                        writeln("sacarEntradas encontró entrada.expr ", entrada.expr, " ruta ", ruta);
                        writeln("nombre ", nombre, " entrada ", entrada);
                        ret[nombre] = entradas;
                    }
                }
            }
        }
        return ret;
    }

    void imprimirCorreos(Appender!string saco, Mail[string] correos) {
        foreach(commit, correo; correos) {
            saco.put(" * " ~ correo.subject);
            saco.put(" [[https://git.kernel.org/linus/" ~ commit ~ "|commit]]\n");
        }
    }

    Mail[string] sacaCorreos(Mail[string] correos, Entry[] entradas) {
        import std.regex : Captures, regex, matchFirst, escaper, Regex;
        import std.conv : to;

        Mail[string] ret;
        foreach(commit, correo; correos) {
            foreach(entrada; entradas) {
                Regex!char expr = regex(entrada.expr.escaper.to!string);
                Captures!string match = matchFirst(correo.diferencias[0].ruta, expr);
                if (!match.empty)
                    ret[commit] = correo;
            }
        }
        return ret;
    }

    Appender!string lista = appender!string;

    // Iterar lista de asociaciones de arriba
    // Por cada asociación, sacar los Subsys afectados (convertidos en menús de segundo nivel)
    // Por cada Subsys, se imprimen los emails relacionados
    foreach(nombreSubsys, rutas; asociaciones.byPair) {
        lista.put("= " ~ nombreSubsys ~ " =\n");
        Subsys filtradas = sacarEntradas(sub, rutas);

        foreach(nombre, entrada; filtradas) {
            Mail[string] filtrados = sacaCorreos(mails, entrada);
            if (filtrados.length > 0)
                lista.put("== " ~ nombre ~ " ==\n");

            imprimirCorreos(lista, filtrados);
            foreach(commit, correo; filtrados)
                mails.remove(commit);
        }
    }
    imprimirCorreos(lista, mails);

    return lista[];
}
