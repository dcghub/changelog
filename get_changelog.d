#!/bin/rdmd

//enum emailpath="/home/dcg/Correo/.linux-kernel.directory/.commits.directory/commitlist/new/";
enum mailPath=`/tmp/foo`;
enum codeRepo="/home/dcg/código/linux";
enum gitRepo = codeRepo ~ "/.git";

alias Entry = string[char][];
alias Maintainers = Entry[string];

struct Mail {
    string subject;
    string[] diff;
}
alias Mails = Mail[string];

void main() {
    Mails mailsData = parseMails();
    Maintainers maint = parseMaintainers();
import std.stdio : writeln;
    foreach(idx, subsys; maint) {
        writeln("Subsys ", idx);
        foreach(entry; subsys) {
            writeln(" Entry ", entry);
        }
    }
}

Mails parseMails() {
    import std.array;
    import std.file : dirEntries, SpanMode, isFile;
    import std.algorithm : filter;

    Mails mails;
    auto files = dirEntries(mailPath, SpanMode.depth)
        .filter!(a => a.isFile)
        .array;

    foreach(file; files) {
        import std.file : readText;
        import std.regex : matchFirst, regex;
        import std.process : execute, Config;
        import std.conv : to;
        import std.string : splitLines;
        import std.stdio : writeln;

        auto buf = readText(file);
        if (buf == "") {
            writeln("WARNING: Void mail " ~ file);
            continue;
        }
        auto expr = regex(`X-Git-Rev: (?P<id>[A-Fa-f0-9]{40})`);
        auto match = matchFirst(buf, expr);
        assert(match.empty == 0, "File didn't contain X-Git-Rev field: " ~ file);
        string commit = match["id"];

        auto diffStat = execute([`git`, `--git-dir=` ~ gitRepo, `show`, `--pretty=format:%s`, `--stat`, commit], null, Config.none, ulong.max, gitRepo);
        assert(diffStat.status == 0, "Git commit failed: " ~ diffStat.to!string);

        Mail email;
        email.subject = diffStat.output.splitLines[0];
        email.diff = diffStat.output.splitLines[1..$-1];
        mails[commit] = email;
    }
    return mails;
}


Maintainers parseMaintainers() {
    import std.stdio : File;

    Maintainers ret;
    auto buf = File(codeRepo ~ "/MAINTAINERS");
    string title = "";

    /*
     * The maintainers file does not have any formal format
     * We detect the "title" by waiting for a newline, then we set the title variable to the next line
     * We reset title after a void line.
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

        if (match.empty == false) {
            import std.conv : to;

            string[] res = split(match.hit.to!string, "\t");
            // Some entries use whitespaces instead of tabs
            if (res.length != 2)
                continue;

            string[char] fill;
            // M:<tab>blah
            fill[line[0]] = line[3..$].to!string;
            ret[title] ~= fill;
        }
    }
    return ret;
}
/*
for fd in os.listdir(emailpath):
#    print(emailpath+fd)
    message = email.message_from_file(open(emailpath+fd, encoding="utf8", errors='ignore'))
    commit=message['X-Git-Commit']
    if commit == None:
#        print("Error")
        commit=message['X-Git-Rev']

#    print("path " + emailpath+fd)
#    print("commit " + commit)
    diffstat = subprocess.run(['git', '--git-dir=/home/dcg/código/linux/.git', 'show', '--pretty=format:', '--no-renames', '--dirstat', commit], stdout=subprocess.PIPE, encoding='utf-8')
#    print(diffstat.stdout)
    
    sorteddiffstat = subprocess.run(['sort', '-gr'], input=diffstat.stdout, stdout=subprocess.PIPE, encoding='utf-8').stdout

    commitdir = ""
    if sorteddiffstat != "":
        firstdir = sorteddiffstat.splitlines()[0].split(sep='% ')[1].split(sep='/')
        commitdir = firstdir[0]
        if len(firstdir) > 2: # git show prints the final directory with slash, so split returns an extra void element
            commitdir += '/' + firstdir[1]

    messagelist.append([commitdir, message['subject'].rstrip('.').strip(), commit])

sortedmessagelist = sorted(messagelist, key=lambda l:l[0]) # sorting is required to properly detect sections

header='''#pragma section-numbers on
#pragma keywords Linux, kernel, operating system, changes, changelog, file system, Linus Torvalds, open source, device drivers
#pragma description Summary of the changes and new features merged in the Linux kernel during the  development cycle

Linux has not been released 

Summary:

<<TableOfContents()>>
= Prominent features =
== =='''

sectionlist=[['Documentation', 'kernel', 'init', 'ipc', 'scripts', 'tools/testing', '= Core (various) ='],
        ['fs', '= File systems ='],
        ['mm', '= Memory management ='],
        ['block', 'drivers/block', 'drivers/md', '= Block layer ='],
        ['tools/perf', 'tools/testing/selftests/bpf', 'tools/lib/bpf', 'tools/bpf/bpftool', 'kernel/bpf', '= Tracing, perf and BPF ='],
        ['virt', 'virt/kvm', 'drivers/xen', 'drivers/vhost', 'drivers/hv', '= Virtualization ='],
        ['crypto', '= Cryptography ='],
        ['security', 'security/apparmor', 'security/selinux', '= Security ='],
        ['net', 'kernel/bpf', 'tools/bpf', '= Networking ='],
        ['arch', '= Architectures ='],
        ['drivers/gpu', 'drivers/video', '= Drivers =\n== Graphics =='],
        ['drivers/acpi', 'tools/power', 'drivers/thermal', '== Power Management =='],
        ['drivers/scsi', 'drivers/ata', 'drivers/nvme', '== Storage =='],
        ['drivers/staging', '== Drivers in the Staging area =='],
        ['drivers/net', 'drivers/bluetooth', 'drivers/infiniband', '== Networking =='],
        ['sound', '== Audio =='],
        ['drivers/input', 'drivers/hid', '== Tablets, touch screens, keyboards, mouses =='],
        ['drivers/media', '== TV tuners, webcams, video capturers =='],
        ['drivers/usb', '== Universal Serial Bus =='],
        ['drivers/spi', '== Serial Peripheral Interface (SPI) =='],
        ['drivers/watchdog', '== Watchdog =='],
        ['drivers/serial', '== Serial =='],
        ['drivers/cpufreq', '== CPU Frequency scaling =='],
        ['drivers/devfreq', '== Device Voltage and Frequency Scaling =='],
        ['drivers/power', 'drivers/regulator', '== Voltage, current regulators, power capping, power supply =='],
        ['drivers/rtc', '== Real Time Clock (RTC) =='],
        ['drivers/pinctrl', '== Pin Controllers (pinctrl) =='],
        ['drivers/mmc', '== Multi Media Card (MMC) =='],
        ['drivers/mtd', '== Memory Technology Devices (MTD) =='],
        ['drivers/iio', '== Industrial I/O (iio) =='],
        ['drivers/mfd', '== Multi Function Devices (MFD) =='],
        ['drivers/pwm', '== Pulse-Width Modulation (PWM) =='],
        ['drivers/i2c', '== Inter-Integrated Circuit (I2C + I3C) =='],
        ['drivers/hwmon', '== Hardware monitoring  (hwmon) =='],
        ['drivers/gpio', '== General Purpose I/O (gpio) =='],
        ['drivers/leds', '== Leds =='],
        ['drivers/dma', '== DMA engines =='],
        ['drivers/clock', '== Clocks =='],
        ['drivers/hwrng', '== Hardware Random Number Generator (hwrng) =='],
        ['drivers/crypto', '== Cryptography hardware acceleration =='],
        ['drivers/pci', '== PCI =='],
        ['drivers/ntb', '== Non-Transparent Bridge (NTB) =='],
        ['drivers/thunderbolt', '== Thunderbolt =='],
        ['drivers/fsi','== FRU Support Interface (FSI) =='],
        ['drivers/clk', 'drivers/clocksource', '== Clock =='],
        ['drivers/phy', '== PHY ("physical layer" framework) =='],
        ['drivers/edac', '== EDAC (Error Detection And Correction) ==']]

footer='''= List of Pull Requests =

= Other news sites ='''

# paths with subpaths like net/ipv4, but grouped around the first path
firstpathasheading=['net', 'kernel', 'sound']

# same, but grouped using the second path as heading
secondpathasheading=['drivers']

# grouped using the first path as heading
secondpathasbullet=['fs', 'arch']

gitpath = 'https://git.kernel.org/linus/'

def removeprefix(message, prefix):
    return message

def findmessageswithpath(targetlist, targetpath, mode):
    laststr = ''
    for i in targetlist[:]:
        splitpath = i[0].split('/')
        if mode == 'secondasbullet' and splitpath[0] == targetpath:
            prefixtoremove = splitpath[0]
            if len(splitpath) > 1 and laststr != splitpath[1]:
#                print('new subsection found!, because len(splitpath) =' + str(len(splitpath)) + ' and laststr != splitpath[1] -> ' + laststr + ' != ' + splitpath[1])
                print(' * ' + splitpath[1].upper())
                laststr = splitpath[1]
                prefixtoremove = splitpath[1]
            print('  * ' + removeprefix(i[1], prefixtoremove) + ' [[' + gitpath + i[2] + '|commit]]')
            sortedmessagelist.pop(sortedmessagelist.index(i))
        if mode == 'secondasheading' and i[0] == targetpath:
            print(' * ' + removeprefix(i[1], splitpath[1]) + ' [[' + gitpath + i[2] + '|commit]]')
            sortedmessagelist.pop(sortedmessagelist.index(i))
        if mode == 'firstasheading' and splitpath[0] == targetpath:
            print(' * ' + removeprefix(i[1], splitpath[0]) + ' [[' + gitpath + i[2] + '|commit]]')
            sortedmessagelist.pop(sortedmessagelist.index(i))


print(header)

for section in sectionlist:
    print(section[-1])

    for itersection in section[:-1]:
        for i in secondpathasbullet:
            if itersection == i:
                findmessageswithpath(sortedmessagelist, itersection, 'secondasbullet')

        splitpath = itersection.split('/')
        if splitpath[0] == secondpathasheading[0]:
            findmessageswithpath(sortedmessagelist, itersection, 'secondasheading')

        for i in firstpathasheading:
            findmessageswithpath(sortedmessagelist, itersection, 'firstasheading')

        findmessageswithpath(sortedmessagelist, itersection, 'secondasheading')





print('\n== Various ==')
for i in sortedmessagelist: print(' * ' + i[1] + ' [[' + gitpath + i[2] + '|commit]]')
print (footer)
*/
