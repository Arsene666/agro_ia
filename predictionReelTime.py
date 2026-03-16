from predictionDefaultTime import predictionDefaultTime
import math
import numpy as np


def predictionReelTime(temperature : float, humidity : float, tomatoState: int):

    # Retourne une erreur pour les valeurs inhabituelles
    if(humidity < 0 or tomatoState < 0 or humidity > 1):
        raise ValueError("Valeur d'humidité et de l'état de la tomate invalide")
    
    if(temperature >= 15):
        k = 0.02
        optimalHumidity = 0.65
    else :
        k = 0.015
        optimalHumidity = 0.9
    
    T_opt = 20
    minDefaultValue = 1 # Valeur de l'etat optimale de la tomate
    maxDefaultValue = 55 # Valeur de l'etat de pourriture optimale de la tomate

    facTeperature = 2**((temperature -T_opt)/10) # facteur de temperature
    facHumidity = 1 + k*abs(humidity - optimalHumidity)*100 # facteur d'humidite
    facMaturity = ((tomatoState - minDefaultValue)/(maxDefaultValue - minDefaultValue))*(3-0.7) + 0.7 # Facteur de maturite
    
    # -------------------- Prediction nombre de jour restant dans les bonnes conditions----------------------------------------------
    """
    modelDefaulTime = predictionDefaultTime(maxDefaultValue)
    defaultTime = int(modelDefaulTime.predict([[tomatoState]]).item()) # Prediction nombre de jour restant dans les bonnes conditions

    """
    #or 

    defaultTime = int (-0.2222*tomatoState + 14.2222) # Apres recuperation des poids du model

    #---------------------------------------------------------------------------------------------------------------------------------

    #print(defaultTime)
    #print(f"{facTeperature}, {facHumidity}, {facMaturity}")

    minColdDeterioration = 0.1 # Intervalle du facteur de deterioration a cause d'un froid excessive
    maxColdDeterioration = 10
    minHotDeterioration = 30 # Intervalle du facteur de deterioration a cause d'une chaleur excessive 
    maxHotDeterioration = 40
    

    # Caltcule du denominateur
    if temperature < maxColdDeterioration and temperature > minColdDeterioration:
        minStress = 0.2
        maxStress = 0.4
        facStress = ((temperature - minColdDeterioration)/(maxColdDeterioration - minColdDeterioration))*(maxStress-minStress) + minStress
        facStress = 1 + facStress
        denominator = facTeperature * facHumidity* facMaturity * facStress
        #print(facStress)
    elif temperature > minHotDeterioration and temperature < maxHotDeterioration:
        minStress = 0.3
        maxStress = 0.6
        facStress = ((1/temperature - minColdDeterioration)/(maxColdDeterioration - minColdDeterioration))*(maxStress-minStress) + minStress
        facStress = 1 + facStress
        denominator = facTeperature * facHumidity* facMaturity * facStress
        #print(facStress)
    elif temperature <= minColdDeterioration:
        denominator = facTeperature * facHumidity* facMaturity * 1.2
        #print("1.2")
    elif temperature >= maxHotDeterioration :
        denominator = facTeperature * facHumidity* facMaturity * 1.6
        #print("1.6")
    else :
        denominator = facTeperature * facHumidity* facMaturity


    reelTime = defaultTime /denominator # Temps biologique reel estant avant pourriture

    alpha = math.exp(-((temperature - T_opt)/15)**2) # Facteur de determination du temps degustatif de qualite entre 0.4 et 0.7
    #print(alpha)

    reelTimeTasting = alpha * reelTime

    return reelTime, reelTimeTasting

