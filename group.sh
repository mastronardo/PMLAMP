#!/bin/bash

# file degli utenti
sudo getent passwd {1000..65533} | cut -f 3,5 -d : | sed 's/,,,//' > users.txt

# file dei gruppi
sudo getent group {1000..65533} | cut -f 1,3 -d : > groups.txt