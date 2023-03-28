#!/usr/bin/perl
use Expect;

print ("Inserisci il nome dello studente: ");
$nome=<>; #Per prendere in input
chomp($nome);
print ("Inserisci il cognome dello studente: ");
$cognome=<>;
chomp($cognome);
$username=lc($nome) . lc($cognome);# lc = Lowercase;
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

# Viene aggiunto il nuovo utente al gruppo studenti
system ("sudo usermod -a -G Studenti " . $username);
$exp->soft_close();