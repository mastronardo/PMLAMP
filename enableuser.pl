#!/usr/bin/perl

print ("Inserisci il nome dello studente: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);

# tramite il comando chage rimuovo la scadenza dell'account dell'utente
system("sudo chage -E -1 " . $username);