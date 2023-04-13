#!/usr/bin/perl

$uid=$<;
if($uid==0){
system("cut -d ':' -f 3,5 /etc/passwd | sort -n > userstemp.txt");
system("sed 's/,,,//' userstemp.txt > users.txt");
system("rm userstemp.txt");

system("cut -d ':' -f 1,3 /etc/group | sort -n > groups.txt");
}