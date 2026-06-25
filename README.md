# TP Pratique â€” Module 2 : Services de calcul Azure
**DurÃ©e estimÃ©e : 50-60 min**  
**PrÃ©requis : accÃ¨s au portail Azure de la formation â€” utiliser votre groupe de ressources existant**

---

## ðŸŽ¯ ScÃ©nario

Vous Ãªtes dÃ©veloppeur DevOps junior chez **AzureTech**. Votre Ã©quipe doit Ã©valuer trois plateformes Azure avant de choisir oÃ¹ hÃ©berger la future API de l'entreprise. Votre mission : dÃ©ployer la mÃªme API basique `GET /hello` sur **App Service**, **Azure Functions** et **Container Instances**, puis comparer les expÃ©riences.

L'API renvoie toujours la mÃªme rÃ©ponse JSON :
```json
{
  "message": "Hello from AzureTech !",
  "service": "[nom du service utilisÃ©]"
}
```

---

## Partie 1 â€” App Service : dÃ©ployer l'API en PaaS (20 min)

> **ModÃ¨le PaaS** â€” vous gÃ©rez le code, Azure gÃ¨re l'OS, le runtime et le serveur web.

### 1.1 CrÃ©er l'App Service

1. Dans le portail **[https://portal.azure.com](https://portal.azure.com)**, cherchez **App Service** â†’ **+ CrÃ©er** â†’ **Application web**.
2. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Groupe de ressources | *(votre groupe de ressources existant)* |
   | Nom | `api-appservice-[votre_prenom]` |
   | Publier | Code |
   | Pile d'exÃ©cution | **PHP 8.2** |
   | SystÃ¨me d'exploitation | Linux |
   | RÃ©gion | France Centre |

3. Dans **Plan App Service** â†’ sÃ©lectionnez le **plan partagÃ© de la formation**.
4. Cliquez **VÃ©rifier + crÃ©er** â†’ **CrÃ©er** â†’ attendez le dÃ©ploiement â†’ **AccÃ©der Ã  la ressource**.

### 1.2 DÃ©ployer le code de l'API

1. Sur la page de votre App Service, dans le menu de gauche, cherchez **Outils de dÃ©veloppement** â†’ **App Service Editor (AperÃ§u)** â†’ **Go â†’**.
2. L'Ã©diteur de code s'ouvre dans un nouvel onglet (interface similaire Ã  VS Code dans le navigateur).
3. Faites un clic droit sur le dossier racine (`/home/site/wwwroot`) â†’ **New File** â†’ nommez-le `index.php`.
4. Collez ce code dans l'Ã©diteur :

```php
<?php
header('Content-Type: application/json');
echo json_encode([
    "message" => "Hello from AzureTech !",
    "service" => "Azure App Service (PaaS)",
    "runtime" => "PHP 8.2",
    "host"    => gethostname()
]);
```

5. Sauvegardez avec **Ctrl+S**.
6. Revenez Ã  l'onglet de votre App Service â†’ cliquez sur l'**URL** de votre application.
7. Vous devriez voir la rÃ©ponse JSON s'afficher âœ…

   > **Question :** Avez-vous installÃ© PHP ? Apache ? Un serveur ? Qu'est-ce que cela illustre sur le modÃ¨le PaaS ?

### 1.3 Tester la scalabilitÃ©

1. Dans le menu de gauche â†’ **Scale out (App Service)** â†’ observez l'option de mise Ã  l'Ã©chelle manuelle et automatique.
2. Notez l'URL de votre API : `https://api-appservice-[votre_prenom].azurewebsites.net` â†’ **vous en aurez besoin pour la comparaison finale**.

---

## Partie 2 â€” Azure Functions : dÃ©ployer l'API en Serverless (18 min)

> **ModÃ¨le Serverless** â€” vous Ã©crivez uniquement la logique. Azure gÃ¨re tout le reste et vous facture Ã  l'exÃ©cution.

### 2.1 CrÃ©er la Function App

1. Dans la barre de recherche, tapez **Function App** â†’ **+ CrÃ©er**.
2. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Groupe de ressources | *(votre groupe de ressources existant)* |
   | Nom | `api-func-[votre_prenom]` |
   | RÃ©gion | France Centre |
   | Pile d'exÃ©cution | **Python** |
   | Version | 3.11 |

3. Onglet **HÃ©bergement** :
   - Plan d'hÃ©bergement : **Consommation (Serverless)** â† gratuit, facturation Ã  l'exÃ©cution
4. Cliquez **VÃ©rifier + crÃ©er** â†’ **CrÃ©er** â†’ attendez (1-2 min) â†’ **AccÃ©der Ã  la ressource**.

### 2.2 CrÃ©er la fonction HTTP

1. Dans le menu de gauche â†’ **Fonctions** â†’ **+ CrÃ©er**.
2. Choisissez :
   - Environnement de dÃ©veloppement : **DÃ©velopper dans le portail**
   - ModÃ¨le : **HTTP trigger**
   - Nom : `hello`
   - Niveau d'autorisation : **Anonymous**
3. Cliquez **CrÃ©er** â†’ attendez quelques secondes.

### 2.3 Modifier le code de l'API

1. Sur la page de votre fonction, cliquez sur **Code + Test** dans le menu de gauche.
2. Remplacez tout le contenu du fichier `__init__.py` par ce code :

```python
import azure.functions as func
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    response = {
        "message": "Hello from AzureTech !",
        "service": "Azure Functions (Serverless)",
        "runtime": "Python 3.11",
        "trigger": "HTTP"
    }
    return func.HttpResponse(
        json.dumps(response),
        mimetype="application/json",
        status_code=200
    )
```

3. Cliquez sur **Enregistrer**.
4. Cliquez sur **Tester/ExÃ©cuter** â†’ **ExÃ©cuter** â†’ observez la rÃ©ponse dans le panneau Output âœ…
5. Cliquez sur **Obtenir l'URL de la fonction** â†’ copiez l'URL et ouvrez-la dans un nouvel onglet.

   > **Question :** Combien de serveurs avez-vous provisionnÃ© ? Que se passe-t-il si 10 000 utilisateurs appellent cette fonction simultanÃ©ment ?

6. Dans le menu de gauche â†’ **Monitor** â†’ observez le tableau des invocations (vos appels de test apparaissent).

---

## Partie 3 â€” Container Instances : dÃ©ployer l'API via un conteneur (10 min)

> **ModÃ¨le Conteneur** â€” vous fournissez une image Docker prÃªte Ã  l'emploi. Azure la dÃ©marre en quelques secondes.

### 3.1 DÃ©ployer le conteneur

1. Dans la barre de recherche, tapez **Container Instances** â†’ **+ CrÃ©er**.
2. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Groupe de ressources | *(votre groupe de ressources existant)* |
   | Nom du conteneur | `api-aci-[votre_prenom]` |
   | RÃ©gion | France Centre |
   | Source d'image | **DÃ©marrage rapide** |
   | Image | `mcr.microsoft.com/azuredocs/aci-helloworld` (prÃ©-sÃ©lectionnÃ©e) |
   | Type de systÃ¨me d'exploitation | Linux |
   | Taille | 1 vCPU, 1.5 Gio (dÃ©faut) |

3. Onglet **RÃ©seau** :
   - Type de rÃ©seau : **Public**
   - Ã‰tiquette du nom DNS : `api-aci-[votre_prenom]`
   - Ports : `80` (TCP) â€” dÃ©jÃ  renseignÃ©
4. Cliquez **VÃ©rifier + crÃ©er** â†’ **CrÃ©er** â†’ attendez le dÃ©ploiement (1-2 min) â†’ **AccÃ©der Ã  la ressource**.

### 3.2 Tester l'API conteneur

1. Sur la page du Container Instance, repÃ©rez le **Nom de domaine complet (FQDN)** dans Vue d'ensemble.
2. Ouvrez `http://[votre-FQDN]` dans un nouvel onglet â†’ vous voyez la page de l'application conteneurisÃ©e âœ…
3. Dans le menu de gauche, cliquez sur **Conteneurs** â†’ **Journaux** â†’ observez les logs de dÃ©marrage du conteneur.
4. Cliquez sur **Se connecter** â†’ observez qu'on peut ouvrir un shell directement dans le conteneur.

   > **Question :** En quoi ACI est-il diffÃ©rent d'une Function App ? Quand prÃ©fÃ©rieriez-vous ACI Ã  une Function ?

---

## Partie 4 â€” Comparaison finale (5 min)

Vous avez maintenant 3 URL actives. Ouvrez-les cÃ´te Ã  cÃ´te dans votre navigateur et comparez :

| CritÃ¨re | App Service | Azure Functions | Container Instances |
|---|---|---|---|
| **URL de votre API** | `azurewebsites.net` | `azurewebsites.net/api/hello` | `[rÃ©gion].azurecontainer.io` |
| **Temps de dÃ©ploiement** | ~2 min | ~2 min | ~1 min |
| **Code dÃ©ployÃ©** | Oui (PHP) | Oui (Python) | Non (image Docker) |
| **Facturation** | Plan mensuel | Ã€ l'exÃ©cution | Ã€ la seconde |
| **Scale automatique** | Oui (plan Standard+) | Oui (natif) | Non (manuel) |
| **Gestion OS** | âŒ Azure | âŒ Azure | âŒ Azure |
| **Gestion runtime** | âŒ Azure | âŒ Azure | âœ… Vous (dans l'image) |

> **Question finale :** Pour une startup qui lance une nouvelle API avec un trafic imprÃ©visible et un budget limitÃ©, quel service choisiriez-vous et pourquoi ?

---

## ðŸ§¹ Nettoyage (3 min)

> âš ï¸ Supprimez vos ressources dans cet ordre pour Ã©viter les erreurs de dÃ©pendance.

1. **Container Instance** â†’ cherchez **Container Instances** â†’ sÃ©lectionnez `api-aci-[votre_prenom]` â†’ **Supprimer** â†’ confirmez.
2. **Function App** â†’ cherchez **Function App** â†’ sÃ©lectionnez `api-func-[votre_prenom]` â†’ **Supprimer** â†’ confirmez.
3. **App Service** â†’ cherchez **App Services** â†’ sÃ©lectionnez `api-appservice-[votre_prenom]` â†’ **Supprimer** â†’ confirmez.

---

## âœ… Ce que vous avez appris

- **App Service (PaaS)** : dÃ©ployez du code directement â€” Azure gÃ¨re l'OS, le runtime et le serveur. IdÃ©al pour les applications web et les API en production.
- **Azure Functions (Serverless)** : Ã©crivez une fonction, Azure l'exÃ©cute Ã  la demande. Facturation Ã  l'exÃ©cution, scaling natif. IdÃ©al pour les traitements Ã©vÃ©nementiels et les APIs lÃ©gÃ¨res.
- **Container Instances** : dÃ©ployez une image Docker en quelques secondes sans gÃ©rer de cluster. IdÃ©al pour les tÃ¢ches isolÃ©es et les dÃ©mos rapides.
- Le mÃªme rÃ©sultat (une API HTTP) peut Ãªtre obtenu de trois faÃ§ons trÃ¨s diffÃ©rentes â€” le choix dÃ©pend du contrÃ´le souhaitÃ©, du coÃ»t et de la charge de gestion.