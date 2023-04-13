#!/usr/bin/perl

"""
Cancellazione di un'utenza e della rispettiva home
"""

print ("Inserisci il nome dello studente che vuoi cancellare: ");
$nome=<>;
chomp($nome);
print ("Inserisci il cognome dello studente che vuoi cancellare: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);
system("sudo deluser --remove-home" . $username);