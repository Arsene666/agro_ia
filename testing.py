from predictionReelTime import predictionReelTime
import random

if __name__ == "__main__" :

    for i in range(30):
        temperature = random.randint(-10,30)
        humidite = random.randint(0,100)/100
        stadeTomate = random.randint(0,55)
        predictReelTime, predictTasting = predictionReelTime(temperature,humidite,stadeTomate)
        DayReelTime = int(predictReelTime)
        HoursReelTime = (predictReelTime - DayReelTime) * 24
        DayTasting = int(predictTasting)
        HoursTasting = (predictTasting - DayTasting) * 24

        print(f"\nTomato state : {stadeTomate}, Temperature : {temperature}, Humidite : {humidite}")
        print(f"\n\nLe temps restant pour la tomate avant pourriture est : {DayReelTime} Jours et {int(HoursReelTime)}H")
        print("")
        print(f"Le temps restant pour la qualite en gout de la tomate est: {DayTasting} Jours et {int(HoursTasting)}H\n\n")
        print("--------------------------------------------------------------------------------------------------------------")