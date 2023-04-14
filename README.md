# PMLAMP
## P(Piccadaci) M(Mastronardo) L(Linux) A(A web server) M(Mysql/Mongodb) P(PHP)
Progetto sviluppato su Debian GNU/Linux 11 (architettura x86) per la gestione di utenti, dove i soli servizi messi a loro disposizione sono:
- un web server (Nginx) per la creazione di pagine web tramite Eclipse PHP IDE;
- database sql e nosql;
- connessione ai database tramite php;

---

# Moduli di Perl
Prima di cominciare bisogna installare tutti i moduli di perl necessari per l'esecuzione degli script.
```bash
perl -MCPAN -e shell # apertura della shell di CPAN (Comprehensive Perl Archive Network)
install Expect
install DBI
install MongoDB
```

---

# Creazione dell'utenza
L'amministratore può creare nuovi utenti e aggiungerli automaticamente al gruppo _Studenti_ tramite lo script ```adduser.pl```.

```perl
use Expect;
print ("Inserisci il nome dello studente: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);
my $exp = new Expect;
$exp->spawn ("sudo adduser " . $username);
$exp->expect (undef,"New password: ");
$exp->send ($username . "\n");
$exp->expect (undef, "Retype new password: ");
$exp->send ($username . "\n");
$exp->expect (undef, "Full Name \[\]: ");
$exp->send ($nome . " " .  $cognome . "\n");
# aggiunta delle altre informazioni ...
$exp->expect (undef, "Is the information correct? ");
$exp->send ("Y\n");
system ("sudo usermod -a -G Studenti " . $username);
```

Le utenze appartenenti al gruppo _Studenti_ hanno i seguenti privilegi:
```perl
system ("sudo mkdir -p /home/Lavori/" . $username);
system ("sudo chown " . $username  . ":administrator /home/Lavori/" . $username);
system ("sudo chmod 770 /home/Lavori/" . $username);
system ("sudo chmod 757 /home/" . $username);
```

_Lavori_ è la cartella condivisa tra gli utenti del gruppo _Studenti_ e l'**amministratore**.
I permessi di lettura, scrittura ed esecuzione sui file all'interno di questa cartella sono concessi esclusivamente all'utente proprietario; invece qualsiasi altro utente ha solo i permessi di lettura.

IMMAGINE DEI PERMESSI

Le suddette utenze non potranno eseguire nessun comando ```sudo``` da terminale perché non fanno parte del ```sudoers group```.

Ogni utente ha la propria home in quanto è stato usato il comando ```adduser```.

L'amministratore può visualizzare la lista dei gruppi e degli utenti presenti nel sistema tramite lo script ```show_user_group.pl```:
```perl
system("cut -d ':' -f 1,3 /etc/group | sort -n > groups.txt");
system("cut -d ':' -f 3,5 /etc/passwd | sort -n > userstemp.txt");
system("sed 's/,,,//' userstemp.txt > users.txt");
system("rm userstemp.txt");
```
IMMAGINE DEI FILE

# Backup della cartella condivisa
Per questioni di sicurezza e/o di integrità del dato, viene effettuato backup delle cartelle degli studenti, collocate nella cartalla condivisa _Lavori_.
Il backup è una cartella nascosta visibile solo all'amministratore e viene create all'interno della cartella _Lavori_.

```bash
cd /home/Lavori
mkdir .backup
sudo chown administrator:administrator .backup
sudo chmod 770 .backup
```

L'amministratore può eseguire il backup in qualiasi momento eseguendo lo script ```Studentsbackup.pl```:
```perl
$studentString = `sudo getent group | cut -f 3,4 -d : | grep 1002 | cut -f 2 -d :`;
my @students = split (',', $studentString);
foreach my $st (@students){
chomp($st);
$filename= "backup-". $st . "-'" . localtime() . "'.tar.gz"; 
system("sudo tar -cvzf /home/Lavori/.backup/" . $filename . " /home/Lavori/" . $st);
}
```

## Cron
Per eseguire il backup seguendo una routine utilizziamo il demone di pianificazione dei lavori basato sul tempo, <b>Cron</b>.

---

# Firewall
Un firewall è un dispositivo, software o hardware, per la sicurezza della rete che permette la gestione del traffico in entrata e in uscita utilizzando una serie predefinita di regole di sicurezza per consentire o bloccare gli eventi.
Ufw (**Uncomplicated firewall**) è l'applicazione per la configurazione del firewall. Sviluppato per semplificare la configurazione di iptables, Ufw offre un modo semplice per creare un firewall basato su protocolli IPv4 e IPv6. Ufw è inizialmente disabilitato.

```bash
sudo apt install ufw # installazione
```

```bash
sudo ufw enable # abilitare il firewall
```

```bash
sudo ufw disable # disabilitare il firewall
```

L'amministratore gestisce il firewall tramtie lo script ```firewall.pl```. Nel seguente caso di studio, il firewall è configurato per consentire l'accesso esclusivamente ai servizi Nginx.

```perl
my @services= split (/\n/, `sudo ufw app list`);

foreach my $service (@services){
    $service=~ s/^\s+|\s+$//g;
    my $command= "sudo ufw deny " . $service . " ";
    if (($service ne "Nginx Full") || ($service ne "Nginx HTTP") || ($service ne "Nginx HTTPS") ||  ($service ne "Available applications:")){
    system ($command);
}

system ('sudo ufw default deny incoming');
system ('sudo ufw default deny outgoing');
system ('sudo ufw enable');
};
```

Per visualizzare lo stato del firewall si lancia il comando:
```bash
sudo ufw status
```
IMMAGINE STATO FIREWALL

---

# Database
Per restare al passo coi tempi abbiamo scelto di utilizzare sia un database sql e che nosql.
## MySql
MySql è un RDBMS open source ed è tra i più diffusi grazie alle seguenti caratteristiche:
- alta efficienza nonostante le moli di dati affidate;
- integrazione di tutte le funzionalità che offrono i migliori DBMS: indici, trigger e stored procedure;
- altissima capacità di integrazione con i principali linguaggi di programmazione, ambienti di sviluppo e suite di programmi da ufficio.

Sempre tramite l'esecuzione dello script ```adduser.pl``` l'amministratore crea le utenze anche in MySql.

```perl
use DBI;

$usernamedb=lc(substr($nome, 0, 1)) . lc($cognome);
$myConnection = DBI->connect("DBI:mysql:mysql:localhost", "root", "adminadmin");
$query = $myConnection->prepare("SET GLOBAL validate_password.policy=LOW");
$result = $query->execute(); 
$query = $myConnection->prepare("CREATE DATABASE " . $username);
$result = $query->execute();
$query = $myConnection->prepare("CREATE USER '" . $usernamedb ."'\@\'localhost\' IDENTIFIED BY '" . $username ."'");
$result = $query->execute();
$query = $myConnection->prepare("REVOKE USAGE ON *.* FROM '" . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
$query = $myConnection->prepare("GRANT ALL PRIVILEGES ON " . $username . ".* TO '" . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
$query = $myConnection->prepare("REVOKE DROP ON " . $username . ".* FROM '"  . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
$query = $myConnection->prepare("FLUSH PRIVILEGES");
$result = $query->execute();
```

IMMAGINE DEI DB

## MongoDb
Il più popolare tra i database NoSql e document-oriented è MongoDb, che utilizza una struttura dati di tipo BSON (Binary JSON), che lo rende molto flessibile. Le caratteristiche principali dell'applicazione sono la facilità delle Query, l'indicizzazione e la possibilità di effettuare sharding e replica, in maniera tale da lasciare all'amministratore la decisione riguardo il trade-off fra velocità e affidabilità dei dati.

Sempre tramite l'esecuzione dello script ```adduser.pl``` l'amministratore crea le utenze anche in MongoDb.
In questo caso, però, prima bisogna disabilitare temporaneamente l'autenticazione agendo sul file di configurazione.

```perl
open my $in, '<', '/etc/mongod.conf';
open my $out, '>', '/etc/mongodtemp.conf';
while ( <$in> ){
print $out $_;
last if $. == 28;
}

my $line = <$in>;
$line= '      authorization: "disabled"' . "\n";
print $out $line;
while ( <$in> ){
print $out $_;}

system ('sudo mv /etc/mongodtemp.conf /etc/mongod.conf');
system ('sudo systemctl restart mongod');
```

Creazione dell'utente, del database e di una collection per mantenere persistente il database, e assegnazione dei privilegi.
```perl
use MongoDB ();
$usernamedb=lc(substr($nome, 0, 1)) . lc($cognome);

$client = MongoDB->connect();
my $db = $client->get_database($username);
$db->run_command(
Tie::IxHash->new(
	createUser  => $usernamedb,
	pwd =>  $username,
	roles => [{role=> "userAdmin", db=> $username}, {role=>"readWrite", db => $username}]
));
my $test = $db->get_collection( "test" );
$test->insert_one({"Ciao!" => "Benvenuto!"});
```

Dopo aver terminato le operazioni si riabilita l'autenticazione sul medesimo file di configurazione

```perl
open my $in, '<', '/etc/mongod.conf';
open my $out, '>', '/etc/mongodtemp.conf';
while ( <$in> ){
print $out $_;
last if $. == 28;
}

my $line = <$in>;
$line= '      authorization: "enabled"' . "\n";
print $out $line;
while ( <$in> ){
print $out $_;}

system ('sudo mv /etc/mongodtemp.conf /etc/mongod.conf');
system ('sudo systemctl restart mongod');
```

IMMAGINE DEI DB

---

# Web server: Nginx
Nginx è software open source all-in-one che include vari servizi:
- web server
- reverse proxy
- HTTP cache
- load balancer
- IPv6
- TLS/SSL with SNI (Server Name Indication)

È progettato per offrire un basso utilizzo della memoria e un'elevata concorrenza. Anziché creare nuovi processi per ogni richiesta Web, Nginx utilizza un approccio asincrono basato sugli eventi in cui le richieste vengono gestite in un singolo thread.

Con Nginx, un processo master può controllare più processi worker. Il master mantiene i processi di lavoro, mentre i lavoratori eseguono l'elaborazione vera e propria. Poiché Nginx è asincrono, ogni richiesta può essere eseguita dal lavoratore contemporaneamente senza bloccare altre richieste.

NGINX è anche spesso posizionato tra i client e un secondo server web, per fungere da terminatore SSL/TLS o acceleratore web. Agendo da intermediario, NGINX gestisce in modo efficiente le attività che potrebbero rallentare il tuo server Web, come la negoziazione di SSL/TLS o la compressione e la memorizzazione nella cache dei contenuti per migliorare le prestazioni.

## Workspace
Dopo aver settato correttamente la workspace dell'amministratore, si procede a creare la workspace dell'utente, per la quale occorre:
- copiare la cartella dell'amministratore nella home dell'utente;
- l'utente diventa il proprietario della cartella ```/home/<USERNAME>/eclipse-workspace```;
- creare una nuova cartella ```/var/www/<USERNAME>``` e rendere l'utente il nuovo proprietario;
- creare un link simbolico tra ```/var/www/<USERNAME>``` e ```/home/<USERNAME>/eclipse-workspace/www```;
- copiare il contenuto della cartella ```/home/administrator/eclipse-workspace/PMLAMP/*``` nella cartella ```/var/www/<USERNAME>``` e rendere l'utente il nuovo proprietario;
- creare un link simbolico tra ```/home/Lavori/<USERNAME>``` e ```/home/<USERNAME>/eclipse-workspace/Lavori```;
- a ogni utente assegnamo un numero di porta diverso, che andremo ad incrementare ad ogni nuova creazione di utente;
- creare e modificare adeguatamente un file di configurazione per il nuovo utente, che andremo a salvare nella cartella ```/etc/nginx/sites-available/```;
- creare un link simbolico tra ```/etc/nginx/sites-available/<USERNAME>``` e ```/etc/nginx/sites-enabled/<USERNAME>```;

```perl
system('sudo cp -r /home/administrator/eclipse-workspace/ /home/' . $username);
system ('sudo chown -R ' . $username . ':' . $username . ' /home/' . $username . '/eclipse-workspace');
system ('sudo mkdir /var/www/' . $username);
system ('sudo chown -R ' . $username . ':' . $username . ' /var/www/' . $username);
system ('sudo ln -s /var/www/' . $username . ' /home/' . $username . '/eclipse-workspace/www');
system ('sudo cp -R /home/administrator/eclipse-workspace/PMLAMP/* /var/www/' . $username);
system ('sudo chown -R ' . $username . ':' . $username . ' /var/www/' . $username);
system ('sudo ln -s /home/Lavori/' . $username . ' /home/' . $username . '/eclipse-workspace/Lavori');

$port= `tail -n 1 /home/administrator/.ports` + 1;
system ('echo "' . $port .'" >> /home/administrator/.ports');
system ('echo "' . $username . ' ' . $port . '" >> /home/administrator/Ports-students');

open my $in, '<', '/etc/nginx/sites-available/example';
open my $out, '>', '/etc/nginx/sites-available/' . $username;

while ( <$in> ){
print $out $_;
last if $. == 1;
}

my $line = <$in>;
$line='    listen ' . $port . ";\n" . '    server_name ' . $username . ' www.' . $username . ';' . "\n" . '    root /var/www/' . $username . ";\n";
print $out $line;
while ( <$in> ){
print $out $_;
}

system ('sudo sed -i "5d" ' . '/etc/nginx/sites-available/' . $username); 
system ('sudo sed -i "5d" ' . '/etc/nginx/sites-available/' . $username); 
system ('sudo ln -s /etc/nginx/sites-available/' . $username . ' /etc/nginx/sites-enabled/' . $username);
system ('sudo systemctl reload nginx');
```

Puoi testare se la configurazione ha errori di sintassi digitando:
```bash
sudo nginx -t
```

IMMAGINE DI UNA WORKSPACE

Creo un file nella home dell'utente con le sue credenziali e il numero di porta assegnato.
```perl
system ('sudo echo "Credenziali MySQL e MongoDb\Username:' . $usernamedb . '\Password: ' . $username . '\Numero di porta: ' . $port . '" > /home/' . $username . '/credentials.txt');
system ('sudo chown ' . $username . ':' . $username . ' /home/' . $username  . '/credentials.txt');
system ('sudo chmod 407 /home/' . $username . '/credentials.txt');
```
IMMAGINE DEL FILE

Per semplificare la user experience aggiunto al file ```bashrc``` l'alias eclipse, in modo da poter avviare l'IDE semplicemente digitando "eclipse" da terminale:
```perl
system ('sudo echo "alias eclipse=\'/home/Lavori/eclipse/eclipse\'" >> /home/' . $username . '/.bashrc');
```

## Accesso ai database tramite PHP
Installazioni necessarie per accedere ai database tramite PHP:
```bash
sudo apt update
sudo apt install php-dev php-fpm php-mysql # installazione delle librerie PHP
sudo apt install nginx
sudo apt install curl
```

### MySql
All'interno del file ```index.php``` la parte di codice che permette di connettersi al database MySql è:
```php
$servername = "localhost";
$username = "<YOUR_URSERNAME>";
$password = "<YOUR_PASSWORD>";

$conn = new mysqli($servername, $username, $password);
if ($conn->connect_error) {
    die("Connessione fallita a MySQL: " . $conn->connect_error);
}
else{
    echo "Connesso a MySql";
}
```

### MongoDb
Per poter interfacciarsi a MongoDb è necessario installare la [libreria MongoDB PHP](https://github.com/mongodb/mongo-php-library).

La libreria MongoDB PHP è un'astrazione di alto livello per il driver PHP (_ovvero l'estensione mongodb_).
- Come installare l'estensione mongodb:
```bash
sudo pecl install mongodb
echo "extension=mongodb.so" >> `php --ini | grep "Loaded Configuration" | sed -e "s|.:\s||"` # aggiunta della stringa extension=mongodb.so nei file php.ini
```

- Come installare la libreria PHP MongoDB:
```bash
curl -sS https://getcomposer.org/installer | php sudo mv composer.phar /usr/bin/composer # installazione del composer | spostare il composer nella directory corretta
composer require mongodb/mongodb # installazione della libreria PHP MongoDB
```


Dopo aver installato tutto il necessario possiamo procedere con l'accesso al database MongoDb.
All'interno del file ```index.php``` la parte di codice che permette di connettersi al database MongoDb è:
```php
$servername = "localhost";
$username = "<YOUR_USERNAME>";
$password = "<YOUR_PASSWORD>";

$m = new MongoDB\Client('mongodb://' . $username . ':' . $password . '@localhost:27017/<YOUR_DB_NAME>');
$db = $m->$password; 
$collection=$db->test;
$result=$collection->find();

foreach ($result as $document) {
    echo $document["Ciao!"] . "\n";
}

echo "Connesso a MongoDb!\n";
```

# Cancellazione dell'utenza
L'amministratore può cancellare un utente tramite lo script ```deluser.pl```.

- Cancellazione dell'utenza e della rispettiva home:
```perl
print ("Inserisci il nome dello studente che vuoi cancellare: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente che vuoi cancellare: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);
system("sudo deluser --remove-home " . $username);
```

- Cancellazione del resto delle cartelle e dei file:
```perl
system ("sudo rm -rf /home/Lavori/" . $username);
system ("sudo rm -rf /var/www/" . $username);
system ("sudo rm /etc/nginx/sites-enabled/" . $username);
system ("sudo rm /etc/nginx/sites-available/" . $username);
```

- Cancellazione del numero di porta assegnato all'utente:
```perl
$string="cat Ports-students | grep $username";
$line=`$string`;
@arr=split(" ", $line);
$port=@arr[1];
system("sed -i -n '/" . $username . "'/!p Ports-students");
system("sed -i -n '/" . $port . "'/!p .ports");
system ("sort .ports");
```

- Cancellazione dell'utente e del personale database da MySQL:
```perl
use DBI;
$usernamedb=lc(substr($nome, 0, 1)) . lc($cognome);

$myConnection = DBI->connect("DBI:mysql:mysql:localhost", "root", "adminadmin");
$query = $myConnection->prepare("DROP DATABASE " . $username);
$result = $query->execute();
$query = $myConnection->prepare("DROP USER '" . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
```

- Cancellazione dell'utente e del personale database da MongoDB:
    1) Disabilitazione temporanea dell'autenticazione agendo sul file di configurazione
    ```perl
    open my $in, '<', '/etc/mongod.conf';
    open my $out, '>', '/etc/mongodtemp.conf';
    while ( <$in> ){
    print $out $_;
    last if $. == 28;
    }

    my $line = <$in>;
    $line= '      authorization: "disabled"' . "\n";
    print $out $line;
    while ( <$in> ){
    print $out $_;}

    system ('sudo mv /etc/mongodtemp.conf /etc/mongod.conf');
    system ('sudo systemctl restart mongod');
    ```

    2) Cancellassione dell'utente e del database
    ```perl
    use MongoDB ();
    $usernamedb=lc(substr($nome, 0, 1)) . lc($cognome);
    my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
    my $db = $client->get_database($username);
    my $result = $db->run_command({'dropUser' => $usernamedb});
    my $resultdb = $db->run_command({'dropDatabase' => 1});
    ```

    3) Riabilitazione dell'autenticazione
    ```perl
    open my $in, '<', '/etc/mongod.conf';
    open my $out, '>', '/etc/mongodtemp.conf';
    while ( <$in> ){
    print $out $_;
    last if $. == 28;
    }

    my $line = <$in>;
    $line= '      authorization: "enabled"' . "\n";
    print $out $line;
    while ( <$in> ){
    print $out $_;}

    system ('sudo mv /etc/mongodtemp.conf /etc/mongod.conf');
    system ('sudo systemctl restart mongod');
    ```
