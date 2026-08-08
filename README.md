# AutoSur : La tarification de l'assurance automobile

<br>

## Description du projet
Ce projet développe un système complet de tarification actuarielle en assurance automobile, implémenté en langage R. L'objectif est d'estimer la prime pure annuelle d'un portefeuille en dissociant la modélisation de la fréquence des sinistres de celle de leur sévérité (coût moyen), conformément aux pratiques standards du marché.

Le pipeline repose sur l'exploitation des bases de données de référence `freMTPL2freq` et `freMTPL2sev` de la bibliothèque `CASdatasets`. La méthodologie couvre l'ensemble du cycle de tarification :
* **Fréquence :** Modélisation par régression de Poisson et Quasi-Poisson pour tenir compte de la surdispersion.
* **Sévérité :** Modélisation par GLM Gamma (lien log) avec pondération par le nombre de sinistres, après écrêtement des valeurs extrêmes.
* **Scoring et Rebouclage (Off-balancing) :** Calcul de la prime pure, annualisation par normalisation de l'exposition, et ajustement global pour garantir l'équilibre technique du portefeuille.
* **Validation :** Analyse du pouvoir discriminant par déciles de risque.

<br>

---

## Chargement des données
* `IDpol` : Identifiant unique du contrat.
* `ClaimNb` : Nombre de sinistres déclarés sur la période d'observation.
* `Exposure` : Durée d'exposition au risque en années (comprise entre 0 et 1).
* `VehPower` : Puissance fiscale du véhicule.
* `VehAge` : Ancienneté du véhicule en années.
* `DrivAge` : Âge du conducteur principal.
* `BonusMalus` : Coefficient de réduction-majoration.
* `VehBrand` : Marque du véhicule (anonymisée).
* `VehGas` : Type de motorisation (Diesel ou Essence).
* `Area` : Zone géographique de résidence.
* `Density` : Densité de population (habitants au kilomètre carré).
* `Region` : Région administrative française.
* `ClaimAmount` : Montant des charges de sinistres associées.

<br>

<br>


---

## 1. Fréquence

### Nettoyage des données
Les graphiques nous montrent la présence de valeurs aberrantes.

<img width="1166" height="874" alt="Rplot01" src="https://github.com/user-attachments/assets/bb3b2b3c-e057-470d-910a-1ef5c6805c4a" />

**Exposition :** Plafonnée strictement à 1 afin de neutraliser les anomalies d'exposition supérieure à une année civile.

---
<img width="1038" height="664" alt="Rplot03" src="https://github.com/user-attachments/assets/84a062cb-5718-4e0e-93c8-be23c163853d" />

**Nombre de sinistres :** un maximum de 16 sinistres a été observé. L'utilisation de la fonction table a permis d'analyser la distribution et de fixer un plafond pertinent à 4 sinistres afin d'éviter l'effet de levier des valeurs extrêmes sur la modélisation.

--- 

**Regroupements de modalités (Binning) :** Les classes de puissance et les marques ont été regroupées par similarité de sinistralité observée pour accroître la volumétrie par classe et garantir la significativité statistique des estimateurs.

<br>

### Analyse graphique
La fréquence globale brute s'établit à **0,073 sinistre** par année-véhicule (soit 7,3 % de sinistralité annuelle moyenne). Les tendances observées confirment les grands classiques actuariels :

<img width="832" height="886" alt="Rplot05" src="https://github.com/user-attachments/assets/43ac0547-731f-4cfe-affc-af130376a6b3" />

**Puissance et motorisation :** Corrélation positive entre la puissance et la fréquence ; surrisque des véhicules diesel lié à une exposition kilométrique accrue.

---
<img width="960" height="878" alt="Rplot06" src="https://github.com/user-attachments/assets/c964be3a-b7d7-44d9-a7c9-e5576695469a" />

**Âge du conducteur :** Mise en évidence du surrisque structurel des jeunes conducteurs et d'une recrudescence du risque aux âges avancés.

---
<img width="1114" height="824" alt="Rplot07" src="https://github.com/user-attachments/assets/133fe63b-faa4-442d-9a15-70d81fc43d84" />

**Bonus-Malus :** Facteur fortement prédictif illustrant l'antisélection et la récidive.

---

### Entraînement du modèle
* **Modèle initial de Poisson :** Une sélection pas-à-pas par critère AIC (`step()`) a permis d'écarter la variable `Region`, non significative et source de surparamétrage.
* **Correction de la surdispersion (Quasi-Poisson) :** La variance empirique étant supérieure à la moyenne, l'utilisation d'un modèle Quasi-Poisson a été privilégiée pour corriger l'underestimation des erreurs standard des coefficients, garantissant ainsi des tests d'hypothèses plus prudents.

<br>

<br>

---

## 2. Sévérité

### Nettoyage des données
Afin d'éviter qu'un sinistre cataclysmique isolé (observé jusqu'à 4 millions d'euros) ne distorde la structure tarifaire de masse, un écrêtement au **quantile 99 %** a été appliqué. Les risques hors normes relèvent par nature d'une couverture en réassurance et non de la tarification de détail.

<br>

### Entraînement du modèle
Contrairement à la fréquence, les caractéristiques du véhicule (puissance, marque) ne se sont pas révélées significatives sur le coût des sinistres ($p\text{-values} > 0,05$). Conformément au principe de parcimonie et aux réalités du marché, seules les variables démontrant une robustesse statistique ont été conservées :
* Loi Gamma (fonction de lien logarithmique).
* **Pondération :** `weights = ClaimNb` (pour refléter le volume de sinistres par ligne de données).
* **Variables retenues :** `BonusMalus` et `VehAge`.

<br>

<br>

---

## 3. Scoring du Portefeuille
Le croisement des modèles de fréquence et de sévérité, après normalisation de l'exposition à un an (`Exposure = 1`), permet de calculer la prime pure de chaque contrat :

$$\text{Prime Pure} = \text{Fréquence Prédite} \times \text{Sévérité Prédite}$$

* **Statistiques du portefeuille :** Une prime pure moyenne de **124,82 €** pour une médiane de **98,16 €**, illustrant l'asymétrie classique de la distribution des risques.
* **Analyse des profils extrêmes :** Le modèle attribue une prime pure maximale de **27 359 €** à un profil cumulant un bonus-malus très élevé (230) et un âge avancé (82 ans). Bien que l'assuré n'ait déclaré aucun sinistre sur la période (`ClaimNb = 0`), le modèle évalue le risque théorique de sa sinistralité future à un niveau critique, justifiant actuariellement une surprime prohibitive ou un refus de garantie.

<br>

<br>

---

## 4. Validation et Rebouclage (Off-balancing)
Afin de concilier la performance technique du modèle (classement des risques) et l'équilibre financier global de l'assureur, une étape de rebouclage a été réalisée :
* **Facteur de rebouclage :** Calcul d'un coefficient multiplicateur global défini par le rapport entre la charge réelle totale des sinistres et la masse totale des primes pures prédites.
* **Ajustement :** Application de ce facteur pour recentrer la masse tarifaire sur les décaissements réels.
* **Analyse par déciles de risque :** Le portefeuille a été segmenté en dix classes égales de la prime prédite la plus faible à la plus élevée.

<br>

<br>

---

## 5. Génération du graphique de validation

<img width="1432" height="900" alt="Rplot08" src="https://github.com/user-attachments/assets/b6b6703f-e23b-4883-b7ee-73e3a05bdd32" />

### Interprétation des résultats :
* **Lift / Pouvoir discriminant :** Le modèle démontre une excellente capacité à ordonner le risque. Les coûts réels moyens augmentent de manière quasi-monotone du premier au neuvième décile.
* **Captation des extrêmes :** Le dixième décile valide la capacité du modèle à identifier les risques lourds, avec une envolée conjointe de la prime et du coût réel.
* **Équilibre financier :** Après rebouclage (*off-balancing*), la superposition quasi-parfaite des courbes sur les déciles 1 à 9 confirme la robustesse et la justesse de l'équilibre technique global du portefeuille.
