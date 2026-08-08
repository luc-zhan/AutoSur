# === Projet AutoSur : La tarification automobile (fréquence-sévérité) ===

# Initialisation
library(dplyr)
library(ggplot2)
library(tidyr)
library(CASdatasets)
library(xts)
library(zoo)

# Chargement des données
data("freMTPL2freq")
data("freMTPL2sev")

# == 1. FRÉQUENCE ==
# Nettoyage des données
anyNA(freMTPL2freq)
anyNA(freMTPL2sev)
boxplot(freMTPL2freq$Exposure, main = "Boîte à moustaches durée contrat (en années)")
boxplot(freMTPL2freq$ClaimNb, main = "Boîte à moustaches nombre de sinistre déclaré")
freMTPL2freq$Exposure <- pmin(freMTPL2freq$Exposure, 1)
freMTPL2freq$ClaimNb <- pmin(freMTPL2freq$ClaimNb, 4)
freMTPL2freq$VehPower <- as.factor(freMTPL2freq$VehPower)

freMTPL2freq <- freMTPL2freq %>%
  mutate(VehPower_Group = case_when(
    VehPower == 4 ~ "4",
    VehPower %in% c(5, 6) ~ "5-6",
    VehPower == 7 ~ "7",
    VehPower == 8 ~ "8",
    VehPower == 9 ~ "9",
    VehPower == 10 ~ "10",
    VehPower == 11 ~ "11",
    VehPower %in% c(12,13,14,15) ~ "12 et plus"
  ),
  VehPower_Group = factor(VehPower_Group, levels = c("4", "5-6", "7", "8", "9", "10", "11", "12 et plus"))
  )
freMTPL2freq <- freMTPL2freq %>%
  mutate(VehBrand_Group = case_when(
    VehBrand %in% c("B14", "B12") ~ "Brand_Low",
    VehBrand %in% c("B1", "B2", "B4", "B6", "B10", "B13") ~ "Brand_Standard",
    VehBrand %in% c("B3", "B5") ~ "Brand_High",
    VehBrand == "B11" ~ "Brand_VeryHigh"
  ),
  VehBrand_Group = factor(VehBrand_Group, levels = c("Brand_Standard", "Brand_Low", "Brand_High", "Brand_VeryHigh"))
  )

# Analyse graphique
frequence_globale <- sum(freMTPL2freq$ClaimNb) / sum(freMTPL2freq$Exposure)
print(paste("Fréquence globale du portefeuille :", round(frequence_globale, 4)))

data_power <- freMTPL2freq %>%
  group_by(VehPower) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_power, aes(x = VehPower, y = Frequence)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par puissance véhicule",
       x = "Puissance du véhicule",
       y = "Fréquence moyenne")

data_gas <- freMTPL2freq %>%
  group_by(VehGas) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_gas, aes(x = VehGas, y = Frequence)) +
  geom_bar(stat = "identity", fill = "brown") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par type de moteur",
       x = "Type de moteur",
       y = "Fréquence moyenne")

data_vage <- freMTPL2freq %>%
  group_by(VehAge) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_vage, aes(x = VehAge, y = Frequence)) +
  geom_bar(stat = "identity", fill = "gold") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par âge du véhicule",
       x = "Âge du véhicule",
       y = "Fréquence moyenne") +
  coord_cartesian(xlim = c(0, 45))

data_dage <- freMTPL2freq %>%
  group_by(DrivAge) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_dage, aes(x = DrivAge, y = Frequence)) +
  geom_bar(stat = "identity", fill = "blue") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par âge du conducteur",
       x = "Âge du conducteur",
       y = "Fréquence moyenne") 

data_bm <- freMTPL2freq %>%
  group_by(BonusMalus) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_bm, aes(x = BonusMalus, y = Frequence)) +
  geom_bar(stat = "identity", fill = "green") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par Coefficient de Réduction-Majoration",
       x = "Coefficient de Réduction-Majoration",
       y = "Fréquence moyenne") 

data_density_class <- freMTPL2freq %>%
  mutate(Density_Class = cut(Density, 
                             breaks = c(-1, 50, 200, 500, 2000, 10000, 30000), 
                             labels = c("1-50", "51-200", "201-500", "501-2000", "2001-10000", "10001-30000"))) %>%
  group_by(Density_Class) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_density_class, aes(x = Density_Class, y = Frequence)) +
  geom_bar(stat = "identity", fill = "pink") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par densité de population",
       x = "Habitant au kilomètre carré",
       y = "Fréquence moyenne") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

data_region <- freMTPL2freq %>%
  group_by(Region) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_region, aes(x = Region, y = Frequence)) +
  geom_bar(stat = "identity", fill = "grey") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par région",
       x = "Région",
       y = "Fréquence moyenne") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

data_brand <- freMTPL2freq %>%
  group_by(VehBrand) %>%
  summarise(Frequence = sum(ClaimNb) / sum(Exposure))
ggplot(data_brand, aes(x = VehBrand, y = Frequence)) +
  geom_bar(stat = "identity", fill = "yellow") +
  theme_minimal() +
  labs(title = "Fréquence des sinistres par marques de voitures",
       x = "Marque de voiture",
       y = "Fréquence moyenne") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Entraînement du modèle
modele_freq_final <- glm(ClaimNb ~ VehPower_Group + VehAge + DrivAge + BonusMalus + 
                           VehBrand_Group + VehGas + Area + offset(log(Exposure)),
                         data = freMTPL2freq, 
                         family = quasipoisson(link = "log"))
summary(modele_freq_final)


# == 2. SÉVÉRITÉ ==
# Nettoyage des données
sev_capped <- freMTPL2sev %>%
  mutate(ClaimAmount_capped = pmin(ClaimAmount, quantile(ClaimAmount, 0.99)))

sev_agg <- sev_capped %>%
  group_by(IDpol) %>%
  summarise(TotalClaimAmount = sum(ClaimAmount_capped))

df_severity_model <- freMTPL2freq %>%
  filter(ClaimNb > 0) %>%
  inner_join(sev_agg, by = "IDpol")

df_severity_model <- df_severity_model %>%
  mutate(AvgClaim = TotalClaimAmount / ClaimNb)

# Entraînement du modèle
modele_sev_final <- glm(AvgClaim ~ VehAge + BonusMalus , 
                       data = df_severity_model, 
                       family = Gamma(link = "log"), 
                       weights = ClaimNb)
summary(modele_sev_final)

# == 3. SCORING DU PORTEFEUILLE ==
df_scoring <- freMTPL2freq %>% mutate(Exposure = 1)
df_scoring$Pred_Freq <- predict(modele_freq_final, newdata = df_scoring, type = "response")
df_scoring$Pred_Sev <- predict(modele_sev_final, newdata = df_scoring, type = "response")
df_scoring$PurePremium <- df_scoring$Pred_Freq * df_scoring$Pred_Sev
summary(df_scoring$PurePremium)
profil_extreme <- df_scoring %>%
  filter(PurePremium == max(PurePremium, na.rm = TRUE))

# == 4. VALIDATION ET REBOUCLAGE (OFF-BALANCING) ==
df_validation <- df_scoring %>%
  left_join(sev_agg, by = "IDpol") %>%
  mutate(TotalClaimAmount = coalesce(TotalClaimAmount, 0))

# Calcul du facteur de rebouclage
facteur_rebouclage <- sum(df_validation$TotalClaimAmount) / sum(df_validation$PurePremium)

df_validation <- df_validation %>%
  mutate(
    PurePremium_Reboucle = PurePremium * facteur_rebouclage,
    Decile = ntile(PurePremium_Reboucle, 10)
  )

df_deciles_reboucles <- df_validation %>%
  group_by(Decile) %>%
  summarise(
    Prime_Rebouclee_Moyenne = mean(PurePremium_Reboucle),
    Cout_Reel_Moyen = sum(TotalClaimAmount, na.rm = TRUE) / sum(Exposure)
  )


# == 5. GENERATION DU GRAPHIQUE DE VALIDATION ==
df_long <- df_deciles_reboucles %>%
  pivot_longer(cols = c(Prime_Rebouclee_Moyenne, Cout_Reel_Moyen), names_to = "Type", values_to = "Montant")

ggplot(df_long, aes(x = Decile, y = Montant, color = Type, group = Type)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 1:10) +
  labs(
    title = "Validation du modèle",
    subtitle = "Comparaison de la Prime Rebouclée et du Coût Réel par décile de risque",
    x = "Décile de risque (1 = Moins risqué, 10 = Plus risqué)",
    y = "Montant moyen (€)",
    color = "Légende :"
  ) +
  scale_color_manual(
    values = c("Prime_Rebouclee_Moyenne" = "blue", "Cout_Reel_Moyen" = "red"),
    labels = c("Coût Réel Moyen", "Prime Prédite & Rebouclée")
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5, color = "gray"),
    legend.position = "bottom"
  )