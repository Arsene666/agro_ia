from predictionReelTime import predictionReelTime
from optimisation import optimisation
import time

if __name__ == "__main__" :
    temperature = -2
    humidite = 0.7
    stadeTomate = 30

    predictReelTime, predictTasting = predictionReelTime(temperature,humidite,stadeTomate)
    DayReelTime = int(predictReelTime)
    HoursReelTime = (predictReelTime - DayReelTime) * 24
    DayTasting = int(predictTasting)
    HoursTasting = (predictTasting - DayTasting) * 24

    print(f"\n\nLe temps restant pour la tomate avant pourriture est : {DayReelTime} Jours et {int(HoursReelTime)}H")
    time.sleep(2)
    print(f"Le temps restant pour la qualite en gout de la tomate est: {DayTasting} Jours et {int(HoursTasting)}H\n\n")
    print("----Recommandation----\n")
    
    Humi_best, Temp_best, Durebio, Duregout = optimisation(stadeTomate)
    extDayReelTime = int(Durebio)
    extHoursReelTime = (Durebio - extDayReelTime) * 24
    extDayTasting = int(Duregout)
    extHoursTasting = (Duregout - extDayTasting) * 24
    time.sleep(2)
    print("Température :", round(Temp_best, 2))
    time.sleep(2)
    print("Humidité :", round(Humi_best, 2))
    time.sleep(2)
    print("Nouvelle durée biologique estimé pour la tomate : {} Jours et {}H".format(extDayReelTime,int(extHoursReelTime)))
    time.sleep(2)
    print("Nouvelle durée gustative estimé pour la tomate : {} Jours et {}H\n\n".format(extDayTasting,int(extHoursTasting)))
