#!/usr/bin/perl

# Moduli
use Expect;
use DBI;
use MongoDB ();

# Creazione e gestione della nuova utenza
print ("Inserisci il nome dello studente: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome); # lc = Lowercase;
my $exp = new Expect;
$exp->spawn ("sudo adduser " . $username);

$exp->expect (undef,"New password: ");
$exp->send ($username . "\n");

$exp->expect (undef, "Retype new password: ");
$exp->send ($username . "\n");

$exp->expect (undef, "Full Name \[\]: ");
$exp->send ($nome . " " .  $cognome . "\n");

$exp->expect (undef, "Room Number \[\]: ");
$exp->send ("\n");

$exp->expect (undef, "Work Phone \[\]: ");
$exp->send ("\n");

$exp->expect (undef, "Home Phone \[\]: ");
$exp->send ("\n");

$exp->expect (undef, "Other []: ");
$exp->send ("\n");

$exp->expect (undef, "Is the information correct? ");
$exp->send ("Y\n");

# Viene aggiunto il nuovo utente al gruppo Studenti
system ("sudo usermod -a -G Studenti " . $username);

system ("sudo mkdir -p /home/Lavori/" . $username); # Creazione della cartella condivisa "Lavori"

# L'amministratore può accedere a tutte le cartelle degli studenti, mentre ogni studente solo alla sua
system ("sudo chown " . $username  . ":administrator /home/Lavori/" . $username);
system ("sudo chmod 770 /home/Lavori/" . $username);

# L'amministratore può accedere a tutte le home degli studenti, mentre ogni studente solo alla sua
system ("sudo chown " . $username  . ":administrator /home/" . $username);
system ("sudo chmod 770 /home/" . $username);
$exp->soft_close(); # Chiude l'istanza di Expect

print ("\nStudente aggiunto correttamente\n");


$usernamedb=lc(substr($nome, 0, 1)) . lc($cognome); # nome utente all'interno dei due database

# Connessione al Db MYSQL per la creazione dell'utente e del relativo db
$myConnection = DBI->connect("DBI:mysql:mysql:localhost", "root", "adminadmin");
$query = $myConnection->prepare("SET GLOBAL validate_password.policy=LOW"); # Permette di creare password con meno di 8 caratteri
$result = $query->execute(); 
$query = $myConnection->prepare("CREATE DATABASE " . $username); # Creazione del database
$result = $query->execute();
$query = $myConnection->prepare("CREATE USER '" . $usernamedb ."'\@\'localhost\' IDENTIFIED BY '" . $username ."'"); # Creazione dell'utente
$result = $query->execute();

# L'utente ha i privilegi per effettuare tutte le operazioni solo e soltanto sul proprio database, a parte il DROP
$query = $myConnection->prepare("REVOKE USAGE ON *.* FROM '" . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
$query = $myConnection->prepare("GRANT ALL PRIVILEGES ON " . $username . ".* TO '" . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
$query = $myConnection->prepare("REVOKE DROP ON " . $username . ".* FROM '"  . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();
$query = $myConnection->prepare("FLUSH PRIVILEGES");
$result = $query->execute();

print ("\nMySQL: Database, utente e privilegi impostati correttamente\n");


# Stesse operazioni per MongoDB
# Affinché si possa aggiungere l'utenza, si disabilita temporanamente l'autenticazione agendo sul file di configurazione
open my $in, '<', '/etc/mongod.conf'; # Leggo il file di configurazione
open my $out, '>', '/etc/mongodtemp.conf'; # Scrivo su un file temporaneo
# Si leggono le prime 28 righe del file di configurazione
while ( <$in> ){
print $out $_;
last if $. == 28;
}

# Si modifica la riga 29
my $line = <$in>;
$line= '      authorization: "disabled"' . "\n";

print $out $line; # Si scrive la riga 29 modificata
# Si scrivono le restanti righe del file di configurazione
while ( <$in> ){ 
print $out $_;
}

system ('sudo mv /etc/mongodtemp.conf /etc/mongod.conf'); # Si sostituisce il file di configurazione originale con quello modificato
system ('sudo systemctl restart mongod'); # Si riavvia il servizio per salvare le modifiche apportate

sleep(2);


$client = MongoDB->connect();
my $db = $client->get_database($username); # Creazione del database
# Creazione dell'utente con i relativi privilegi
$db->run_command(
Tie::IxHash->new( # Tie::IxHash è un modulo che permette di mantenere l'ordine di inserimento degli elementi
	createUser  => $usernamedb,
	pwd =>  $username,
	roles => [{role=> "userAdmin", db=> $username}, {role=>"readWrite", db => $username}]
));
my $test = $db->get_collection( "test" ); # Creazione della collection
$test->insert_one({"Ciao!" => "Benvenuto!"}); # Inserimento di un document

# Dopo aver terminato le operazioni, si riabilita l'autenticazione agendo nuovamente sul file di configurazione
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

print ("\nMongoDb: Database, utente e privilegi impostati correttamente\n");


# Creazione della workspace con le dipendenze necessarie
system('sudo cp -r /home/administrator/eclipse-workspace/ /home/' . $username);
system ('sudo chown -R ' . $username . ':' . $username . ' /home/' . $username . '/eclipse-workspace');
system ('sudo mkdir /var/www/' . $username);
system ('sudo chown -R ' . $username . ':' . $username . ' /var/www/' . $username);
system ('sudo ln -s /var/www/' . $username . ' /home/' . $username . '/eclipse-workspace/www');
system ('sudo cp -R /home/administrator/eclipse-workspace/PMLAMP/* /var/www/' . $username);
system ('sudo chown -R ' . $username . ':' . $username . ' /var/www/' . $username);
system ('sudo ln -s /home/Lavori/' . $username . ' /home/' . $username . '/eclipse-workspace/Lavori');

$port= `tail -n 1 /home/administrator/.ports` + 1; # la porta assegnata a un nuovo utente è sempre la successiva a quella dell'utente precedente
system ('echo "' . $port .'" >> /home/administrator/.ports'); # Aggiunge il nuovo numero di porta al file .ports
system ('echo "' . $username . ' ' . $port . '" >> /home/administrator/Ports-students'); # Aggiunge la corrispondenza tra username e porta al file Ports-students

open my $in, '<', '/etc/nginx/sites-available/example'; # Leggo l'esempio di configurazione di un sito
open my $out, '>', '/etc/nginx/sites-available/' . $username; # Scrivo la configurazione per il sito dell'utente

# Si leggono la prima riga del file di esempio
while ( <$in> ){
print $out $_;
last if $. == 1;
}

# Si modifica la riga 2
my $line = <$in>; 
$line='    listen ' . $port . ";\n" . '    server_name ' . $username . ' www.' . $username . ';' . "\n" . '    root /var/www/' . $username . ";\n";

print $out $line; # Si scrive la riga 2 modificata
while ( <$in> ){ # Si scrivono le restanti righe del file di esempio
print $out $_;
}

system ('sudo sed -i "5d" ' . '/etc/nginx/sites-available/' . $username); 
system ('sudo sed -i "5d" ' . '/etc/nginx/sites-available/' . $username); 
system ('sudo ln -s /etc/nginx/sites-available/' . $username . ' /etc/nginx/sites-enabled/' . $username);
system ('sudo systemctl reload nginx');

# Scrivo un file nella home dell'utente con le sue credenziali
system ('sudo echo "Credenziali MySQL e MongoDb\Username:' . $usernamedb . '\Password: ' . $username . '\Numero di porta: ' . $port . '" > /home/' . $username . '/credentials.txt');
system ('sudo chown ' . $username . ':administrator /home/' . $username  . '/credentials.txt');
system ('sudo chmod 470 /home/' . $username . '/credentials.txt');

# Modifica del bashrc in modo da poter avviare l'IDE soltanto digitando "eclipse" da terminale
system ('sudo echo "alias eclipse=\'/home/Lavori/eclipse/eclipse\'" >> /home/' . $username . '/.bashrc');

# Ogni studente verrà aggiunto al file cron.deny in modo da non poter utilizzare il servizio cron
system ('sudo echo "' . $username'" >> /etc/cron.deny');

print ("\nUtente creato correttamente\n");