# bashConf

Jag blir galen(galnaRE) av att underhålla .bashrc, och /root/bin/ i alla varianter, och med diverse smarta grejjer man hittar på nittiotolv olika maskiner. För att inte nämna strulet när man hoppar mellan bsd och linux.

Jag har numera mina original .bashrc* i /root/bashConf, och synkar dem till /root/.bashrc* med checkBashConf.sh.

Sen har jag numera en bin/ katalog som har (optional) underkataloger som kan innehålla ytterligare script som skall läggas till i PATH.

Sen är min .bashrc splittat i ett gäng olika följande filer:

.bashrc .bashrc.alias .bashrc.$(hostname -s) bashrc.$(uname -s) .bashrc.complete .bashrc.env .bashrc.functions .bashrc.git .bashrc.init

Det betyder att på balrog, så finns det:

.bashrc .bashrc.alias .bashrc.balrog bashrc.OpenBSD .bashrc.complete .bashrc.env .bashrc.functions .bashrc.git .bashrc.init

medans på vimes finns det:

.bashrc .bashrc.alias .bashrc.vimes bashrc.Linux .bashrc.complete .bashrc.env .bashrc.functions .bashrc.git .bashrc.init

Dylika bin/vimes/ och bin/Linux directories, läggs till PATH, OM de finns.

Egentligen var ju tanken att mitt git-repo skulle använda git-branches för att hålla isär BSD och Suse, men det var visat sig enklare att hålla saker i .bashrc.balrog, eller dylikt istället.

Ta en titt om det låter intressant. Jag skulle gärna köra det på samtliga våra servrar.

TQ
