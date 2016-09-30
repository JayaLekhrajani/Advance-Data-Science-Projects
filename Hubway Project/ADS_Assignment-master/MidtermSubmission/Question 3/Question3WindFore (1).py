
# coding: utf-8

# In[1]:

import statsmodels.api as sm
import dateutil
import re
import matplotlib.pyplot as plt
from pandas import DataFrame
from numpy import nan
from __future__ import division
import pandas as pd
import numpy as np
from sklearn.tree import DecisionTreeRegressor
from sklearn import tree
from datetime import datetime
from math import sqrt
from sklearn.metrics import mean_squared_error
from sklearn.metrics import mean_absolute_error
from sklearn.metrics import r2_score
from sklearn.metrics import mean_squared_error as MSE
from sklearn.metrics import mean_absolute_error
from pybrain.datasets.supervised import SupervisedDataSet as SDS
from pybrain.tools.shortcuts import buildNetwork
from pybrain.supervised.trainers import BackpropTrainer


# In[2]:

def initialCleansing(fName):
    #input file read and creating dataframe
    createdDF = pd.read_csv("C:/Users/Abhijeet/Desktop/Midterm/"+fName)
    #creating date out of string
    createdDF['date'] = map(lambda x: datetime.strptime(str(x), '%Y%m%d%H'), createdDF.date)
    createdDF = createdDF.set_index('date')
    return createdDF


# In[3]:

def olsPrediction(yTrain, xTrain, xTest,yTest):
    olsPr= sm.OLS(yTrain, xTrain).fit()
    predictions = olsPr.predict(xTest)
    print("##########################################################")
    print("#########Performance Metrics for Linear Regression #######")
    print("##########################################################")
    print(olsPr.summary())
    print(olsPr.params)
    print("R square ")
    print(olsPr.rsquared)
    print("RMSE")
    print(mean_squared_error(yTest, predictions)**0.5)
    print("Mean Absoulute Error")
    print(mean_absolute_error(yTest, predictions))
    return predictions


# In[4]:

def treePrediction(yTrain, xTrain, xTest,yTest):
    clf = tree.DecisionTreeClassifier()
    clf = clf.fit(xTrain, yTrain.astype(str))
    predictions = clf.predict(xTest)
    print("##########################################################")
    print("#########Performance Metrics for Regression Tree #######")
    print("##########################################################")
    print("Regresssion tree Mean squared Error")
    print(mean_squared_error(yTest, predictions))
    print("Regresssion tree Mean Absoulute Error")
    print(mean_absolute_error(yTest, predictions))
    return predictions


# In[6]:

def pred_with_ann(train_y, train_x, test_x, test_y):
    hidden_size = 100
    epochs = 5
    train_y = train_y.reshape( -1, 1 )
    test_y = test_y.reshape( -1, 1 )
    #For labels
    y_test_dummy = np.zeros( test_y.shape )
    input_size = train_x.shape[1]
    target_size = train_y.shape[1]
    # prepare dataset
    ds = SDS( input_size, target_size )
    ds.setField( 'input', train_x )
    ds.setField( 'target', train_y )
    # init and train
    net = buildNetwork( input_size, hidden_size, target_size, bias = True )
    trainer = BackpropTrainer( net,ds )
    #fnn = buildNetwork( trndata.indim, 5, trndata.outdim, outclass=SoftmaxLayer )
    #trainer = BackpropTrainer( fnn, dataset=trndata, momentum=0.1, verbose=True, weightdecay=0.01)
    print("##########################################################")
    print("#########Performance Metrics for Neural Network #######")
    print("##########################################################")
    print("training for {} epochs...".format( epochs ))
    for i in range( epochs ):
        mse = trainer.train()
        rmse = sqrt( mse )
        print("training RMSE, epoch {}: {}".format( i + 1, rmse ))
    #predict
    # init and train and prepare dataset for predictions
    input_size1 = test_x.shape[1]
    target_size1 = test_y.shape[1]
    assert( net.indim == input_size1)
    assert( net.outdim == target_size1)
    ds1 = SDS( input_size1, target_size1 )
    ds1.setField( 'input', test_x )
    ds1.setField( 'target', test_y )
    #train_mse, validation_mse = trainer.trainUntilConvergence( verbose = True, validationProportion = validation_proportion,maxEpochs = epochs, continueEpochs = continue_epochs )
    # predict
    print("Prediction")
    p = net.activateOnDataset( ds1 )
    mse1 = MSE( test_y, p )
    rmse1 = sqrt( mse1 )
    print ("RMSE:")  
    print(rmse1)
    #p=p.reshape( -1, 1 )
    print("Mean Absoulute Error")
    print(mean_absolute_error(test_y, p))
    #print("Prediction Values")
    #print(p)
    return p


# In[7]:

def farmForecast(farm,hors_to_keep = [1]):
    #read windforecasts_wf file for each farm and create dataframe.
    forecast_file = "windforecasts_wf" + str(farm) + ".csv"
    forecast = initialCleansing(forecast_file)
    #print(forecast)
    forecast = forecast[forecast.hors.apply(lambda x: x in hors_to_keep)]
    #print(forecast)
    forecast = forecast.pivot(index=forecast.index, columns='hors')	 
    #name will have forecast field and hours ahead the forecast happened
    forecast.columns = [x[0] + "_" + str(x[1]) for x in forecast.columns]
    forecast['farm'] = farm
    #setting index to farm
    forecast.set_index('farm', drop=True, append=True, inplace=True)
    return forecast


# In[8]:

def farmOutput(farm, ocDataframe):
    #Take farm number and df of all outcome.  Return df with wind speeds at that farm.
    farm_dat = DataFrame(data={'outcome': ocDataframe["wp"+str(farm)], 'farm': farm, 'id': ocDataframe.id}, index=ocDataframe.index)
    farm_dat.set_index('farm', drop=True, append=True, inplace=True)
    return farm_dat


# In[9]:

def intialDataFrame():
    farmList = range(1,8)
    train= initialCleansing("train.csv")
    benchmark = initialCleansing("benchmark.csv")
    #union of beachmark and train files
    initialData = train.append(benchmark)
    #initialData.to_csv("C:/Users/Abhijeet/Desktop/Midterm/initialData.csv", header=True)
    #frame for each farm and creating a single frame
    outcomeAll  = reduce(lambda x,y: x.append(y),(farmOutput(x, initialData) for x in farmList))
    #outcomeAll.to_csv("C:/Users/Abhijeet/Desktop/Midterm/outcomeAll.csv", header=True)
    forecastAll = reduce(lambda x,y: x.append(y),[farmForecast(x) for x in farmList])
    #forecastAll.to_csv("C:/Users/Abhijeet/Desktop/Midterm/forecastAll.csv", header=True)
    dataAll= outcomeAll.merge(forecastAll, left_index=True, right_index=True, how="left")
    #dataAll.to_csv("C:/Users/Abhijeet/Desktop/Midterm/dataAll.csv", header=True)
    temp = dataAll.id
    #print(temp)
    #interpolatg the records
    output = dataAll.apply(pd.Series.interpolate)
    #output.to_csv("C:/Users/Abhijeet/Desktop/Midterm/output.csv", header=True)
    output.id = temp
    return output


# In[10]:

def splitingDataset(initialDF):
    #takes data frame as given in output of intialDataFrame and returns a series containing
    #training outcomes, a df containing the explanatory data in the training set, and a df
    #containing training data for the test set
    output = initialDF.reset_index()
    output['month'] = map(lambda x: x.month, output.date)
    output['hour']  = map(lambda x: x.hour, output.date)
    output['farmnum']  = output.farm
    training = initialDF.id.isnull()
    #print(training)
    output.set_index(['date', 'farmnum'], drop=True, append=False, inplace=True)
    xVar = output.columns.drop(['id', 'outcome'])
    xTrain = output.ix[training, xVar] 
    yTrain = output.outcome[training]
    xTest = output.ix[training==False, xVar]
    yTest=output.outcome[training==False]
    #print(str(len(yTest))+"ytrain"+str(len(yTrain))+"xtest"+str(len(xTest))+"xtrain"+str(len(xTrain)))
    #print("YTEST")
    #print(yTest)
    #print("YTrain")
    #print(yTrain)
    vIndex = DataFrame(output.ix[training==False, 'id'])
    return (yTrain, xTrain, xTest,yTest, vIndex)


# In[11]:

def outputPrediction(predictions, xTest, vIndex):
    usPrediction = DataFrame(data={'prediction': predictions, 'id': vIndex.id}, index=xTest.index).unstack()
    output = DataFrame(data = {'id':map(int, usPrediction.ix[:,1]),
    'date':map(lambda x: x.strftime('%Y%m%d%H'), usPrediction.index),
    'wp1':  usPrediction.ix[:,7],
    'wp2':  usPrediction.ix[:,8],
    'wp3':  usPrediction.ix[:,9],
    'wp4':  usPrediction.ix[:,10],
    'wp5':  usPrediction.ix[:,11],
    'wp6':  usPrediction.ix[:,12],
    'wp7':  usPrediction.ix[:,13]})
    output.set_index('id', inplace=True)
    return output


# In[12]:

def runFunctions():
    basic_data = intialDataFrame()
    basic_data.to_csv("C:/Users/Abhijeet/Desktop/Midterm/cleasedDataset.csv")
    yTrain, xTrain, xTest,yTest, vIndex = splitingDataset(basic_data)
    treePredictions= treePrediction(yTrain, xTrain, xTest,yTest)
    frameOutTP = outputPrediction(treePredictions, xTest, vIndex)
    frameOutTP.to_csv("C:/Users/Abhijeet/Desktop/Midterm/TreePredictedFile.csv", header=True)
    linearPredictions= olsPrediction(yTrain, xTrain, xTest,yTest)
    frameOutLP = outputPrediction(linearPredictions, xTest, vIndex)
    frameOutLP.to_csv("C:/Users/Abhijeet/Desktop/Midterm/linearPredictionFile.csv", header=True)
    neuralNetworkPredictions= pred_with_ann(yTrain, xTrain, xTest,yTest)
    neuralNetworkPredictionss = neuralNetworkPredictions.reshape(-1)
    frameOutNP = outputPrediction(neuralNetworkPredictionss, xTest, vIndex)
    frameOutNP.to_csv("C:/Users/Abhijeet/Desktop/Midterm/NeuralPredictionFile.csv", header=True)


# In[13]:

runFunctions()


# In[ ]:



