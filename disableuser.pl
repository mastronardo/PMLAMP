#!/usr/bin/perl

print ("Inserisci il nome dello studente: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);

# tramite il comando chage imposto la scadenza dell'account dell'utente
system("sudo chage -E0 " . $username);