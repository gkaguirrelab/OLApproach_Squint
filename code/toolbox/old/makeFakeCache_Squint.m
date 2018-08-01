function [ fakeCache ] = makeFakeCache_Squint(DirectionObject)

observerAge = DirectionObject.describe.observerAge;

fakeCache.computeMethod = 'ReceptorIsolate';
fakeCache.data(observerAge).params.receptorIsolateMode = 'Standard';
fakeCache.data(observerAge).backgroundPrimary = DirectionObject.describe.backgroundNominal.differentialPrimaryValues;
fakeCache.data(observerAge).differencePrimary = DirectionObject.differentialPrimaryValues;
fakeCache.data(observerAge).describe.photoreceptors = DirectionObject.describe.photoreceptorClasses;
fakeCache.data(observerAge).describe.T_receptors = DirectionObject.describe.T_receptors;

end