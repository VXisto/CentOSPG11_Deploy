#!/bin/bash

printf "\nDeploy Server CentOS + PostgreSQL 11 v1.0\n"
printf "==========================================================\n\n"
printf "Feito por: Vitor Xisto - vitorxisto@hotmail.com\n"
printf "\n"
echo "Você está configurando este servidor em um local com proxy?"
	while true
	do
		echo "[0] Nao"
		echo "[1] Sim"
		read OPTPROXY
		if (($OPTPROXY != 0)) && (($OPTPROXY != 1)); then
			echo "Opção inválida"
		else 
			if (($OPTPROXY == 0)); then	
			        break
			else 
		         echo "Digite seu Login de proxy:"
                 read LOGINPX
                 echo "Digite sua senha de proxy"
                 read SENHAPX
				 echo "Digite o IP do Proxy"
				 echo "Ex: 10.0.0.1"
				 read IPPROXY
				 echo "Digite a porta do proxy"
				 read PORTPROXY
                 export https_proxy=http://$LOGINPX:$SENHAPX@$IPPROXY:$PORTPROXY
                 export http_proxy=http://$LOGINPX:$SENHAPX@$IPPROXY:$PORTPROXY
                 echo "Proxy configurado para Yum/DNF"
			fi
			break
		fi
	done
printf "==========================================================\n\n"
echo "O servidor está particionado da forma recomendada? (/dados/ para banco e pasta compartilhada)"
	while true
	do
		echo "[0] Nao, sem particionamento"
		echo "[1] Nao, particionamento em /home/database/data"
		echo "[2] Nao, particionamento em outra pasta (especifique)"
		echo "[3] Sim, /dados/database/data"
		read OPTPART
		if (($OPTPART != 0)) && (($OPTPART != 1)) && (($OPTPART != 2)) && (($OPTPART != 3)); then
			echo "Opção inválida"
		else 
			if (($OPTPART == 0)); then	
			      	touch /root/localdata && touch /root/localpasta
				echo "DATALOCAL=/var/lib/pgsql/11/data" >> /root/localdata
				echo "PASTALOCAL=/shared" >> /root/localpasta
				file1="/root/localdata"
				file2="/root/localpasta"
				read -d $'\x' DATALOCAL < "$file1"
				read -d $'\x' PASTALOCAL < "$file2"
				export $DATALOCAL
				export $PASTALOCAL
				sleep 3				
				echo $DATALOCAL
				echo $PASTALOCAL
			elif (($OPTPART == 1)); then
				mkdir /home/database/
				mkdir /home/shared/
				touch /root/localdata && touch /root/localpasta
				echo "DATALOCAL=/home/database" >> /root/localdata
				echo "PASTALOCAL=/home/shared" >> /root/localpasta
				file1="/root/localdata"
				file2="/root/localpasta"
				read -d $'\x' DATALOCAL < "$file1"
				read -d $'\x' PASTALOCAL < "$file2"
				export $DATALOCAL
				export $PASTALOCAL
				sleep 3				
				echo $DATALOCAL
				echo $PASTALOCAL 
						                
				#$DATALOCAL='/home/database/'
				#$PASTALOCAL='/home/shared/'
			elif (($OPTPART == 2)); then
				echo "Digite EXATAMENTE o caminho onde os dados (banco e pasta shared) estarao"		                
				echo "\n Exemplo: /caminho/do/particionamento/"
				read DATALOCAL_OP2
				mkdir $DATALOCAL_OP2/database/
				mkdir $DATALOCAL_OP2/shared
				touch /root/localdata && touch /root/localpasta
				echo "DATALOCAL='$DATALOCAL_OP2'/database" >> /root/localdata
				echo "PASTALOCAL='$DATALOCAL_OP2'/shared" >> /root/localpasta
				file1="/root/localdata"
				file2="/root/localpasta"
				read -d $'\x' DATALOCAL < "$file1"
				read -d $'\x' PASTALOCAL < "$file2"
				export $DATALOCAL
				export $PASTALOCAL
				sleep 3				
				echo $DATALOCAL
				echo $PASTALOCAL 
				#$DATALOCAL="'$DATALOCAL_OP2'/database/"
				#$PASTALOCAL="'$DATALOCAL_OP2'/shared"
			elif (($OPTPART == 3)); then		
				mkdir /dados/database/
				mkdir /dados/shared/
				touch /root/localdata && touch /root/localpasta
				echo "DATALOCAL=/dados/database" >> /root/localdata
				echo "PASTALOCAL=/dados/shared" >> /root/localpasta
				file1="/root/localdata"
				file2="/root/localpasta"
				read -d $'\x' DATALOCAL < "$file1"
				read -d $'\x' PASTALOCAL < "$file2"
				export $DATALOCAL
				export $PASTALOCAL
				sleep 3				
				echo $DATALOCAL
				echo $PASTALOCAL 
				
		                #$DATALOCAL='/dados/database/'
				#$PASTALOCAL='/dados/shared/'
                                
			fi
			break
		fi
	done
printf "==========================================================\n\n"
echo "Instalando pacotes necessários"
yum install -q -y mlocate
printf "==========================================================\n\n"
echo "Instalando DNF - Dandifyed Yum | Yum Melhorado"
yum install -q -y dnf
printf "==========================================================\n\n"
echo "Instalando EPEL - Pacotes extras CentOS"
yum install -q -y epel-release.noarch
printf "==========================================================\n\n"
echo "Instalando HTOP, wget, lshw e samba caso não houver"
yum install -q -y htop lshw wget samba
printf "==========================================================\n\n"
echo "Atualizando pacotes essenciais"
yum update -q -y 
printf "==========================================================\n\n"
echo "Criando estrutura de pastas"
mkdir -p $PASTALOCAL/util
mkdir -p $PASTALOCAL/backup
chmod -R 2777 $PASTALOCAL
printf "==========================================================\n\n"
echo "Checando se será necessario modificar o smb.conf (Config Samba)"
if (($OPTPART == 0)); then
	cd $PASTALOCAL/util
	wget http://vxisto.com/smb_nopart.conf
	mv smb_nopart.conf smb.conf	
	mv /etc/samba/smb.conf /etc/samba/smb.conf.bk
	cp $PASTALOCAL/util/smb.conf /etc/samba/
else
	cd $PASTALOCAL/util
	wget http://vxisto.com/smb_partcustom.conf
	mv smb_partcustom.conf smb.conf	
	sed -i '42i\        path = '$PASTALOCAL'' smb.conf 
	mv /etc/samba/smb.conf /etc/samba/smb.conf.bk
	cp $PASTALOCAL/util/smb.conf /etc/samba/
fi
printf "==========================================================\n\n"

firewall-cmd --permanent --zone=public --add-service=samba
firewall-cmd --reload

systemctl disable firewalld
systemctl stop firewalld

systemctl enable smb.service
systemctl enable nmb.service
systemctl restart smb.service
systemctl restart nmb.service
chcon -t samba_share_t $PASTALOCAL
chcon -t samba_share_t $PASTALOCAL/backup
updatedb
printf "==========================================================\n\n"
echo "Baixando e instalando repositório do PostgreSQL 11"
yum -q -y localinstall https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
printf "==========================================================\n\n"
echo "Baixando e instalando o SGBD PostgreSQL 11"
yum -q -y install postgresql11 postgresql11-server postgres*11*contrib
printf "==========================================================\n\n"
echo "Habilitando o serviço do banco e adicionando para o boot"
systemctl enable postgresql-11
chkconfig postgresql-11 on
printf "==========================================================\n\n"
echo "Iniciando o SGBD para criar a pasta data"
/usr/pgsql-11/bin/postgresql-11-setup initdb
printf "==========================================================\n\n"
echo "Checando se será necessario mudar a pasta data de local"
if (($OPTPART == 0)); then
	break
else
printf "==========================================================\n\n"
	echo "Parando o banco e modificando pasta data de local"
	service postgresql-11 stop
	mkdir -p $DATALOCAL/data
	chown -R postgres:postgres $DATALOCAL/*
	rsync -avh /var/lib/pgsql/11/data/ $DATALOCAL/data
	mv /var/lib/pgsql/ /var/lib/pgsql_old/
	printf "==========================================================\n\n"
	echo "Abrindo editor vi para editar o serviço do Postgres para mudar a pasta data"
	echo "Altere a variavel PGDATA para '$DATALOCAL'"
	echo "Não esqueça de sair gravando com :wq ou :wq!"
	sleep 6
	vi /usr/lib/systemd/system/postgresql-11.service
	systemctl daemon-reload
	printf "==========================================================\n\n"
	echo "Executando serviço do banco para subir na nova pasta data"
	service postgresql-11 start
fi
printf "==========================================================\n\n"
echo "Baixando e configurando backup"
printf "==========================================================\n\n"
if (($OPTPART == 0)); then
	cd $PASTALOCAL/util
	wget http://vxisto.com/backupbd.zip
	unzip backupbd.zip
	sed -i '8i\PATH_BK="/shared/backup"' bk_bd
	sed -i '44i\find /shared/backup -type f -mtime +3 -delete' bk_bd
	cp bk_vr-yum /usr/local/bin/
	chmod +x /usr/local/bin/bk_vr-yum
	
else
	cd $PASTALOCAL/util
	wget http://vxisto.com/backupbd.zip
	unzip backupbd.zip
	sed -i '8i\PATH_BK="'$PASTALOCAL'/backup"' bk_bd
	sed -i '42i\find '$PASTALOCAL'/backup -type f -mtime +3 -delete' bk_bd	
	cp bk_bd /usr/local/bin/
	chmod +x /usr/local/bin/bk_bd
fi
printf "==========================================================\n\n"
echo "Você deseja usar o crontab padrao (22h para backup)"
	while true
	do
		echo "[0] Nao"
		echo "[1] Sim"
		read OPTBACKUP
		if (($OPTBACKUP != 0)) && (($OPTBACKUP != 1)); then
			echo "Opção inválida"
		else 
			if (($OPTBACKUP == 0)); then
                                echo "Abrindo arquivo crontab para edicao do backup"
                                echo "Não esqueça de sair gravando com :wq ou :wq!"
                                vi /etc/crontab	
			        break
			else 
		                echo "Alterando crontab para padrão informado acima"
                                mv /etc/crontab /etc/crontab.bk
                                cp $PASTALOCAL/util/crontab /etc/
                                echo "Crontab modificado"
			fi
			break
		fi
	done

#touch /root/localdata
#echo "DATALOCAL='$DATALOCAL'" >> /root/localdata
cd /root/
wget vxisto.com/GerenciadorPostgres.sh
chmod +x GerenciadorPostgres.sh
echo "Instalacao finalizada, execute agora o GerenciadorPostgres"
