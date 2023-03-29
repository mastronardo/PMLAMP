#!/usr/bin/perl

# all'interno di un array salvo i nomi di tutte i servizi che ufw riconosce
my @services= split (/\n/, `sudo ufw app list`); # splitto la stringa in un array

# eseguo il comando per ogni servizio, ma verrano eseguiti solo quelli Nginx
foreach my $service (@services){
    $service=~ s/^\s+|\s+$//g; # rimuovo gli spazi bianchi iniziali e finali
    my $command= "sudo ufw deny " . $service . " ";
    if (($service ne "Nginx Full") || ($service ne "Nginx HTTP") || ($service ne "Nginx HTTPS") ||  ($service ne "Available applications:")){
    system ($command);
}

system ('sudo ufw default deny incoming'); # blocco tutto il traffico in entrata
system ('sudo ufw default deny outgoing'); # blocco tutte il traffico in uscita
system ('sudo ufw enable'); # abilito il firewall
};