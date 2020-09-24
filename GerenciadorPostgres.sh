#!/bin/bash
#Recuperando local da pasta data feito pelo ServerDeploy
DATALOCALCK="/var/lib/pgsql/11/data"
file="/root/localdata"
read -d $'\x' DATALOCAL < "$file"
if ("$DATALOCALCK" == "$DATALOCAL"); then
	echo "DATALOCAL=/var/lib/pgsql/11" >> /root/localdata
	read -d $'\x' DATALOCAL < "$file"
	echo $DATALOCAL 
	export $DATALOCAL
else
	echo $DATALOCAL 
	export $DATALOCAL

fi

#Setado variavel global para pasta data

bdport = $(cat $DATALOCAL/data/postgresql.conf | grep 'port =' | cut -c8-13 )
export $bdport

#Setado váriavel da porta do SGBD

function fail {
	echo $1
	exit
}

function modPostgresconf {
	echo "Gerando backup do arquivo postgresql.conf"
	cp $DATALOCAL/data/postgresql.conf $DATALOCAL/data/postgresql.conf.bk
	echo "Abrindo arquivo..."
	echo "Não esqueça de sair gravando com :wq ou :wq!"
	sleep 6
	vi $DATALOCAL/data/postgresql.conf
	service postgresql-11 stop && service postgresql-11 start
	
}

function modPGhbaconf {
	echo "Gerando backup do arquivo pg_hba.conf"
	cp $DATALOCAL/data/pg_hba.conf $DATALOCAL/data/pg_hba.conf.bk
	echo "Abrindo arquivo..."
	echo "Não esqueça de sair gravando com :wq ou :wq!"
	sleep 6
	vi $DATALOCAL/data/pg_hba.conf
	service postgresql-11 stop && service postgresql-11 start
	
}

function criarRoles {
	export PGPASSWORD= #insiraasenha
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "CREATE USER teste WITH ENCRYPTED PASSWORD 'teste';"
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "CREATE ROLE pgsql LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE REPLICATION;"
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "ALTER USER postgres WITH ENCRYPTED PASSWORD 'teste';"
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "ALTER USER pgsql WITH ENCRYPTED PASSWORD 'teste';"
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "CREATE USER teste;"
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "CREATE ROLE teste;"
	/usr/pgsql-11/bin/psql -U postgres -p $bdport -c "CREATE DATABASE teste;"
	
}

function atualizarScriptBk {
	echo "Gerando backup do arquivo bk_bd"
	cp /usr/local/bin/bk_bd /usr/local/bin/bk_bd.bk
	echo "Abrindo arquivo..."
	echo "Não esqueça de sair gravando com :wq ou :wq!"
	sleep 6
	vi /usr/local/bin/bk_bd
	
}

function atualizarCrontab {
	echo "Gerando backup do arquivo crontab"
	cp /etc/crontab /etc/crontab.bk
	echo "Abrindo arquivo..."
	echo "Não esqueça de sair gravando com :wq ou :wq!"
	sleep 6	
	vi /etc/crontab
	
}

function consolePsql {
	echo "DICA: para sair do console, só executar o comando \q"
	sleep 6
	sudo -u postgres psql -p $bdport
	
}

function restoreBackup {
	echo "AVISO! Tome MUITO cuidado ao usar o restore"
	echo "preencha corretamente as informaçoes antes de restaurar"
	printf "\n"
	echo "Informe a porta para restauração"
	read PORTA
	echo "Informe quantos nucleos (total, tanto físico quanto logico/multi-threaded) o pc tem"
	read NUCLEO
	echo "Informe qual a base de dados para restauracao, ex: vr"
	read BASE
	echo "Informe qual o caminho COMPLETO do arquivo de backup"
	echo "Exemplo: /dados/shared/backup/backup.bk"
	read CAMINHOBK
	pg_restore -U postgres -v -p $PORTA -j$NUCLEO -Fc -d $BASE $CAMINHOBK
	
}


printf "\nGerenciadorPostgres - By Xisto v1.0\n"
printf "==========================================================\n\n"
printf "AVISO: É necessario que tenha sido usado o ServerDeploy\n\n"

PS3='Por favor escolha uma opção: '

options=("Modificar postgresql.conf" 
 "Modificar pg_hba.conf"
 "Criar Roles e Banco"
 "Atualizar script de backup"
 "Atualizar crontab"
 "Abrir console psql"
 "Restaurar backup"
 "Sair")

select opt in "${options[@]}"
do
    case "$REPLY" in
		1 ) modPostgresconf || fail "Falha ao abrir postgresql.conf" ;;
		2 ) modPGhbaconf || fail "Falha ao abrir pg_hba.conf" ;;
		3 ) criarRoles || fail "Falha ao criar roles" ;;
		4 ) atualizarScriptBk || fail "Falha ao atualizar script de backup" ;;
		5 ) atualizarCrontab || fail "Falha ao atualizar crontab" ;;
		6 ) consolePsql || fail "Falha ao abrir console PSQL" ;;
		7 ) restoreBackup || fail "Falha ao restaurar backup" ;;
		8 ) break ;;
        *) echo "Opção Inválida $REPLY";;
    esac
done
