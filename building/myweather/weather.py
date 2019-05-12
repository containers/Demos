import requests
from pprint import pprint
def weather_data(query):
	res=requests.get('http://api.openweathermap.org/data/2.5/weather?'+query+'&APPID=b35975e18dc93725acb092f7272cc6b8&units=metric');
	return res.json();
def print_weather(result,city):
	fahrenheit = (result['main']['temp'] * 1.8) + 32
	mph = (result['wind']['speed'] * 2.237)
	print("{}'s temperature: {}°F | {}°C ".format(city,round(fahrenheit, 2),round(result['main']['temp'], 2)))
	print("Wind speed: {} mph | {} m/s".format(round(mph, 2),round(result['wind']['speed'], 2)))
	print("Description: {}".format(result['weather'][0]['description']))
	print("Weather: {}".format(result['weather'][0]['main']))
def main():
	city=input('Enter the city: ')
	print()
	try:
	  query='q='+city;
	  w_data=weather_data(query);
	  print_weather(w_data, city)
	  print()
	except:
	  print('City name not found...')
if __name__=='__main__':
	main()
