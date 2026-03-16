import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error

def predictionDefaultTime(totalValue):
    Y = np.linspace(2,14,totalValue).reshape(-1,1)
    X = np.linspace(1,totalValue,totalValue)
    X = np.flip(X).reshape(-1,1)

    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2, random_state=42)
    model = LinearRegression()
    model.fit(X_train,Y_train)
    Y_pred = model.predict(X_test)
    mse = mean_squared_error(Y_test, Y_pred)
    #print("Mean Squared Error:", mse)
    #print(f"{model.coef_} et {model.intercept_}")
    #print(model.predict(np.array([31.365]).reshape(-1,1)))
    return model 