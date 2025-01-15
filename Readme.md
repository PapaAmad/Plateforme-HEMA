# Mon Projet

> <span style="color: #8a2be2; font-size: 1.2em;">❗ Important</span>  
> La branche de développement pourrait être instable en ce moment en raison des nombreuses modifications majeures à venir.  
> **Il est donc recommandé d’utiliser la version stable disponible sur la branche `master`.**

Veuillez noter que les anciennes versions n’utilisent aucun *foundation model* ; ils seront introduits dans les futures versions.

---

## Documentation obsolète

Veuillez noter que la documentation et ce README ne sont plus à jour.  
Nous avons effectué d’importants changements ces derniers mois, notamment :

- Introduction de **nouveaux moteurs de TTS et d’ASR**  
- Approche hybride combinant **LLM, classification simple et multiples techniques NLP**  
- Objectif : **vitesse optimale**, **personnalisation** et **précision**  

Une mise à jour complète de la documentation officielle est prévue pour la sortie officielle.

---

## Historique du projet & plans futurs

Depuis 2017, ce projet a connu de nombreuses transformations. Nous avons parfois été irréguliers dans les mises à jour, mais nous nous concentrons désormais sur la maturité du projet. Avec l’intégration récente de modèles basés sur des Transformers, nous sommes prêts à libérer pleinement son potentiel.

Prochaines étapes :

1. Finaliser les dernières fonctionnalités pour la release officielle.  
2. Mettre en place un groupe de contributeurs actifs pour collaborer, développer de nouvelles “skills” et les partager avec la communauté.  
3. Créer une plateforme de “skill registry” (similaire à npm ou PyPI, mais pour nos Skills).

J’aimerais consacrer plus de temps à ce projet, mais j’ai actuellement d’autres contraintes financières. Des idées de monétisation sont à l’étude (le cœur restera open source), mais cela prendra du temps.

Toute aide financière via [un sponsoring](#) est donc très appréciée 🙂

---

## Dernière version

Consultez le [dernier article de blog sur la release](#).

![Visuel de la Release v8-beta](https://user-images.githubusercontent.com/placeholder/demo.png)

- **Environnement Python non requis au runtime**  
- **Réécrit en TypeScript**  
- **Nouveau codebase**  
- **Service de télémétrie**  
- **Service de rapports & plus encore !**

---

## Introduction

Ceci est un assistant personnel open-source pouvant s’exécuter sur votre propre serveur.

### Pourquoi ?

1. Si vous êtes développeur (ou non), vous souhaiterez peut-être créer de nombreux outils pour votre quotidien.  
   Plutôt que d’écrire un projet dédié pour chaque idée, vous pouvez tout regrouper via la structure “Skills”.

2. Chacun peut alors créer ses propres Skills et les partager.  
   Ainsi, il n’y a qu’un “core” unique (pour les gouverner tous).

3. Le projet utilise des concepts d’IA, ce qui est plutôt sympa.

4. La **vie privée** est importante : vous pouvez configurer l’assistant pour discuter **hors ligne**, sans services tiers.

5. L’open source, c’est génial.

---

## À quoi sert ce dépôt ?

Ce dépôt contient les nœuds suivants :

- **Le serveur**  
- **Les Skills**  
- **L’application web**  
- **Le module de “hotword”** (activation vocale)  
- **Le serveur TCP** (communication inter-processus avec des nœuds tiers, ex. spaCy)  
- **Le pont Python** (connecteur entre le “core” et les Skills écrits en Python)

---

## De quoi est capable l’assistant ?

- Gérer des commandes vocales (STT/TTS)
- Prendre en charge des interactions textuelles
- Gérer plusieurs “skills” dédiées à différentes tâches
- Vous permettre de créer et partager vos propres “skills”

*(D’autres fonctionnalités arriveront dans la documentation...)*

---

## Prérequis

Assurez-vous d’avoir installé :

- **Node.js** (version X ou supérieure)  
- **npm** ou **yarn**  
- **Python** (version 3.x)

Pour installer ces dépendances, consultez la [section How To](#) de la documentation.

---

## Installation

```bash
# Installer le CLI
npm install --global @leon-ai/cli

# Installer la version stable du projet
leon create birth

# OU installer depuis la branche develop
leon create birth --develop
