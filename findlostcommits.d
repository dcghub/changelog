#!/bin/rdmd
// I got unsubscribed to the lkml mailing list; I needed to check which commits
// I don't have them in my maildir commit dir

enum mailDir = `/home/dcg/Correo/.linux-kernel.directory/commits/`;
enum repo = `/home/dcg/código/linux`;
//enum mailDir = "/tmp/foo";
//enum repo = ".";
enum gitDir = repo ~ `/.git`;

void main(string[] args) {
    import std.stdio : writeln;
    import std.path : baseName;
    import std.file : mkdir;

    string script = args[0].baseName;
    assert(args.length == 3, "Incorrect number of parameters. Run " ~ script ~ " <git ref1> <git ref2>");

    mkdir("missed");
    string gitRange = args[1] ~ ".." ~ args[2];
    string[] missingCommits = getCommits(gitRange);
    writeln(missingCommits);
    generateMails(missingCommits);
}

string[] getCommits(string gitRange) {
    import std.stdio : writeln;
    import std.process : execute, Config;
    import std.string : splitLines;
    import std.file : dirEntries, SpanMode, isFile;
    import std.algorithm : filter;
    import std.conv : to;
    import std.parallelism : parallel;
    import std.array;

    auto listCommits = execute(["git", "rev-list", gitRange, "--no-merges"], null, Config.none, ulong.max, gitDir);
    assert(listCommits.status == 0, "Git command failed: " ~ listCommits.to!string);
    string[] missingCommits = listCommits.output.splitLines;
    writeln(typeid(missingCommits));
    writeln(missingCommits);
    auto commitFiles = dirEntries(mailDir, SpanMode.depth)
        .filter!(a => a.isFile)
        .array;
    
    foreach(file; parallel(commitFiles)) {
        import std.file : readText;
        import std.regex : matchFirst, regex;

        writeln("Searching in ", file);
        auto buf = readText(file);
        auto expr = regex(`X-Git-Rev: (?P<id>[A-Fa-f0-9]{40})`);
        auto match = matchFirst(buf, expr);
        assert(match.empty == 0, "File didn't contain X-Git-Rev field");
 
        foreach(commitId; listCommits.output.splitLines)
        {
            import std.string : strip;

            string commit = commitId.strip;
            if (commit == match["id"])
                missingCommits = missingCommits.filter!(x => x != commit).array;
        }
    }
    return missingCommits;
}

void generateMails(string[] missingCommits) {
    import std.process : execute, Config;
    import std.string : strip;

    string gitCmd(string format, string commit) {
        auto res = execute(["git", "show", "--no-patch", "--pretty=format:\"" ~ format ~ "\"", commit], null, Config.none, ulong.max, gitDir);
        assert(res.status == 0, "Git show with format " ~ format ~ "for commit " ~ commit ~ " failed.");
        return res.output.strip.strip("`");
    }
    
    foreach(commit; missingCommits) {
        import std.datetime.systime : Clock;
        import std.stdio : File, write;

        auto parent = gitCmd("%P", commit);
        import std.stdio : writeln; writeln(typeid(parent));
        auto author = gitCmd("%an", commit);
        auto email = gitCmd("%ae", commit);
        auto authorDate = gitCmd("%ad", commit);
        auto committer = gitCmd("%cn", commit);
        auto committerDate = gitCmd("%cD", commit);
        auto committerEmail = gitCmd("%ce", commit);
        auto subject = gitCmd("%s", commit);
        auto currentDate = Clock.currTime().toISOExtString();
        
        auto stat = execute(["git", "show", "--patch", "--pretty=format:%s%n%n%b", commit], null, Config.none, ulong.max, gitDir);
        writeln(stat);
        assert(stat.status == 0, "Git show stat failed.");

        auto emailContent = "From FINDLOSTCOMMITS " ~ currentDate ~ "\n" ~ 
        "Date: " ~ committerDate ~ "\n" ~ 
        "From: diegocg@gmail.com\n" ~
        "To: diegocg@gmail.com\n" ~
        "Content-Type: text/plain; charset=utf-8\n" ~
        "Content-Transfer-Encoding: 8bit\n" ~
        "X-Git-Rev: " ~ commit ~ "\n" ~
        "X-Git-Parent: " ~ parent ~ "\n" ~
        "Subject: " ~ subject ~ "\n\n" ~
        "Commit:     " ~ commit ~ "\n" ~
        "Parent:     " ~ parent ~ "\n" ~
        "Refname:    refs/heads/master\n" ~
        "Web:        https://git.kernel.org/torvalds/c/" ~ commit ~ "\n" ~
        "Author:     " ~ author ~ "\n" ~
        "AuthorDate: " ~ authorDate ~ "\n" ~
        "Committer:  " ~ committer ~ "\n" ~
        "CommitDate: " ~ committerDate ~ "\n\n" ~ stat.output.strip;

        File emailFile = File("missed/" ~ commit ~ ".eml", "w");
        emailFile.write(emailContent);
    }

}
