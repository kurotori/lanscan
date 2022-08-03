
#!/bin/bash

ssh  usuario@172.16.2.119 'scanimage --mode Color>/home/usuario/escaneos/imagen.pnm'
scp usuario@172.16.2.119:/home/usuario/escaneos/imagen.pnm imagen.pnm
