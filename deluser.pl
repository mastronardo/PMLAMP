#!/usr/bin/perl
use DBI;
use MongoDB ();

# Cancellazione di un'utenza e della rispettiva home
print ("Inserisci il nome dello studente che vuoi cancellare: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente che vuoi cancellare: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);
$usernamedb=lc(substr($nome, 0, 1)) . lc($cognome);
system("sudo deluser --remove-home " . $username);

# Cancellazione del resto delle cartelle e dei file
system ("sudo rm -rf /home/Lavori/" . $username);
system ("sudo rm -rf /var/www/" . $username);
system ("sudo rm /etc/nginx/sites-enabled/" . $username);
system ("sudo rm /etc/nginx/sites-available/" . $username);

# Cancellazione del numero di porta assegnato all'utente
$string="cat Ports-students | grep $username"; # Cerca la riga con il nome dell'utente
$line=`$string`; # Salva la riga in una variabile
@arr=split(" ", $line); # Divide la riga in un array
$port=@arr[1]; # Prende il secondo elemento dell'array, ovvero il numero di porta
system("sed -i -n '/" . $username . "'/!p Ports-students"); # Cancella la riga con il nome dell'utente dal file Ports-students
system("sed -i -n '/" . $port . "'/!p .ports"); # Cancella la riga con il numero di porta dal file .ports
system ("sort .ports"); # Ordina il file .ports

# Cancellazione dell'utente e del personale database da MySQL
$myConnection = DBI->connect("DBI:mysql:mysql:localhost", "root", "adminadmin");
$query = $myConnection->prepare("DROP DATABASE " . $username);
$result = $query->execute();
$query = $myConnection->prepare("DROP USER '" . $usernamedb . "\'\@\'localhost'");
$result = $query->execute();

# Cancellazione dell'utente e del personale database da MongoDB
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

sleep(2);

my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $db = $client->get_database($username);
my $result = $db->run_command({'dropUser' => $usernamedb});
my $resultdb = $db->run_command({'dropDatabase' => 1});

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

print ("Utente cancellato correttamente\n");