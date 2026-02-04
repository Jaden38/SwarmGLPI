# Documentation SwarmGLPI

**Auteur :** Nithard Damien M2 AL

## Aperçu

SwarmGLPI est une stack Docker Swarm qui déploie GLPI (gestion de parc informatique) avec :
- 3 réplicas Nginx en reverse proxy avec terminaison SSL
- Application web GLPI
- Base de données MariaDB
- Gestion des certificats Let's Encrypt (Certbot)

## Architecture

```
                    ┌─────────────────┐
                    │   Internet/     │
                    │   Client        │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Nginx (x3)     │
                    │  Terminaison SSL│
                    │  Load Balancer  │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         │          ┌────────▼────────┐          │
         │          │      GLPI       │          │
         │          │  Application Web│          │
         │          └────────┬────────┘          │
         │                   │                   │
         │          ┌────────▼────────┐          │
         │          │    MariaDB      │          │
         │          │  Base de données│          │
         │          └─────────────────┘          │
         │                                       │
         │              Réseau Backend           │
         └───────────────────────────────────────┘
```

## Prérequis

- Docker avec mode Swarm activé
- Terraform >= 1.0
- Ansible >= 2.9

## Démarrage rapide

### 1. Initialiser Docker Swarm

```bash
docker swarm init
```

### 2. Configurer les secrets

```bash
cd ansible/vars
cp secrets.yml.example secrets.yml
# Modifier secrets.yml avec vos mots de passe
```

### 3. Créer les variables Terraform

```bash
cat > terraform/terraform.tfvars <<EOF
glpi_db_password      = "votre_mot_de_passe_securise"
glpi_db_root_password = "votre_mot_de_passe_root_securise"
domain                = "glpi.local"
EOF
```

### 4. Déployer l'infrastructure avec Terraform

```bash
cd terraform
terraform init
terraform apply
cd ..
```

### 5. Déployer la stack Docker

```bash
docker stack deploy -c docker-stack.yml glpi
```

### 6. Attendre le démarrage des services

```bash
docker service ls
# Attendre que tous les réplicas affichent X/X (ex: 3/3, 1/1)
```

### 7. Exécuter la configuration Ansible

```bash
cd ansible
ansible-playbook -i inventory.yml playbook.yml
```

### 8. Compléter l'installation GLPI

Ajouter dans votre fichier hosts :
```
127.0.0.1 glpi.local
```

Puis accéder à : https://glpi.local/install/install.php

Paramètres de connexion à la base de données :
- Hôte : `mariadb`
- Base de données : `glpi`
- Utilisateur : `glpi`
- Mot de passe : (celui défini dans secrets.yml)

### 9. Sécurisation post-installation

Après avoir terminé l'installation de GLPI, bloquer le répertoire install en modifiant `nginx/nginx.conf` :

Changer :
```nginx
location ~ ^/(config|files|scripts|locales)/ {
```

Par :
```nginx
location ~ ^/(config|files|scripts|install|locales)/ {
```

Puis mettre à jour nginx :
```bash
cat nginx/nginx.conf | docker run --rm -i -v glpi_nginx_conf:/conf alpine sh -c 'cat > /conf/default.conf'
docker service update --force glpi_nginx
```

## Identifiants par défaut

Après l'installation de GLPI :
| Utilisateur | Mot de passe | Rôle |
|-------------|--------------|------|
| glpi | glpi | Super-admin |
| tech | tech | Technicien |
| normal | normal | Utilisateur normal |
| post-only | postonly | Post-only |

**Changez ces mots de passe immédiatement après la première connexion !**

## Certificats SSL

### Développement (Certificat auto-signé)

En environnement local/développement, un certificat auto-signé est généré automatiquement par Ansible. Le navigateur affichera un avertissement "Non sécurisé" car le certificat n'est pas émis par une autorité de certification reconnue. **La connexion reste chiffrée.**

### Production (Let's Encrypt)

L'infrastructure est **prête pour Let's Encrypt** avec le conteneur Certbot inclus dans la stack.

**Prérequis pour Let's Encrypt :**
- Un **nom de domaine public** (ex: `glpi.votredomaine.com`)
- **Ports 80/443 accessibles depuis Internet**
- **DNS pointant vers l'IP de votre serveur**

**Options de domaine gratuit :**
- **DuckDNS** - `votrenom.duckdns.org` (gratuit, simple)
- **FreeDNS** (afraid.org) - sous-domaines gratuits
- **No-IP** - DNS dynamique gratuit

**Configuration pour la production :**

1. Modifier `ansible/vars/secrets.yml` :
   ```yaml
   use_self_signed_cert: false
   ```

2. Modifier `ansible/inventory.yml` avec votre domaine :
   ```yaml
   glpi_domain: "glpi.votredomaine.com"
   ```

3. S'assurer que les ports 80/443 sont accessibles depuis Internet

4. Configurer le DNS pour pointer vers votre serveur

5. Exécuter Certbot pour obtenir le certificat :
   ```bash
   docker exec $(docker ps -q -f name=glpi_certbot) certbot certonly \
     --webroot -w /var/www/certbot \
     -d glpi.votredomaine.com \
     --agree-tos --email votre@email.com
   ```

## Référence des commandes

```bash
# Vérifier l'état de la stack
docker stack ls
docker service ls

# Voir les logs des services
docker service logs glpi_nginx
docker service logs glpi_glpi
docker service logs glpi_mariadb

# Mettre à l'échelle les réplicas nginx
docker service scale glpi_nginx=5

# Supprimer la stack
docker stack rm glpi

# Supprimer les ressources Terraform
cd terraform && terraform destroy
```

## Démontage complet

```bash
# Supprimer la stack
docker stack rm glpi

# Supprimer les ressources Terraform
cd terraform && terraform destroy -auto-approve

# Nettoyer les volumes (ATTENTION : supprime toutes les données)
docker volume rm glpi_data glpi_db_data glpi_certs glpi_nginx_conf

# Nettoyer les réseaux
docker network rm glpi_frontend glpi_backend
```

## Dépannage

### Les services ne démarrent pas
```bash
docker service ps glpi_nginx --no-trunc
docker service ps glpi_glpi --no-trunc
```

### Problèmes de connexion à la base de données
```bash
docker exec -it $(docker ps -q -f name=glpi_mariadb) mysql -u root -p
```

### Commandes CLI GLPI
```bash
docker exec -it $(docker ps -q -f name=glpi_glpi) php /var/www/html/glpi/bin/console
```
