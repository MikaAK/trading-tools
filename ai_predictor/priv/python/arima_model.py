import numpy as np
import pandas as pd
import pathlib

from statsmodels.tsa.arima.model import ARIMA
from pandas import DataFrame
from sklearn.metrics import mean_squared_error

def predict(symbol):
  # Read Stock Data
  current_path = pathlib.Path(__file__).parent.resolve()
  stock_csv_path = current_path.joinpath(
    '../datasets/{}.csv'
      .format(symbol.decode("utf-8"))
      #  .replace("b'", "")
      #  .replace("'", "")
  )

  stock_data = pd.read_csv(stock_csv_path)

  # Grab Date & Close
  training_data = stock_data.iloc[-400:-60, [0, 4]]
  validation_data = stock_data.iloc[-60:, [0, 4]]

  # Split Test & Training
  training_items = training_data["Close"].values
  testing_items = validation_data["Close"].values

  # Build Model
  history = [x for x in training_items]
  model_predictions = []
  N_test_observations = len(testing_items)

  # Rolling Forecast
  for time_point in range(N_test_observations):
    model = ARIMA(history, order=(4,1,0))
    model_fit = model.fit()
    output = model_fit.forecast()
    yhat = output[0]
    model_predictions.append(yhat)
    true_test_value = testing_items[time_point]
    history.append(true_test_value)

  MSE_error = mean_squared_error(testing_items, model_predictions)
  print('Testing Mean Squared Error is {}'.format(MSE_error))

  model = ARIMA(history, order=(4,1,0))
  model_fit = model.fit()
  result = model_fit.forecast()[0]

  return str(result)
