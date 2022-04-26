--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

-- This script will fix head models:
-- If player doesn't have the headmodel then generic face will be used
-- If player have headmodel then it will be applied

local valid_headmodels = {
    27, -- Joe Cole
    41, -- Andres Iniesta Lujan
    51, -- Alan Shearer
    240, -- Roy Keane
    241, -- Ryan Giggs
    246, -- Paul Scholes
    250, -- David Beckham
    330, -- Robbie Keane
    388, -- Sol Campbell
    524, -- Lars Ricken
    570, -- Jayjay Okocha
    942, -- Vieri
    1025, -- Rui Costa
    1040, -- Roberto Carlos
    1041, -- Javier Zanetti
    1067, -- Antonio Conte
    1075, -- Alessandro Del Piero
    1088, -- Alessandro Nesta
    1109, -- Maldini
    1114, -- Roberto Baggio
    1116, -- Desailly
    1179, -- Gianluigi Buffon
    1183, -- Cannavaro
    1198, -- Inzaghi
    1201, -- Zola
    1256, -- Clarence Seedorf
    1397, -- Zidane
    1419, -- Vieira
    1605, -- Robert Pires
    1620, -- Emmanuel Petit
    1625, -- Thierry Henry
    1668, -- Claude Makelele
    1845, -- Ole Gunnar Solskjaer
    2147, -- Maarten Stekelenburg
    3647, -- Michael Ballack
    4000, -- Bergkamp
    4202, -- Ivan Gennaro Gattuso
    4231, -- Rivaldo
    4833, -- Hristo Stoichkov
    5003, -- Cafu
    5419, -- Michael Owen
    5471, -- Frank Lampard
    5479, -- Iker Casillas
    5571, -- Diego Simeone
    5589, -- Luis Figo
    5661, -- Fernando Morientes
    5673, -- Jari Litmanen
    5680, -- Kluivert
    5681, -- Marc Overmars
    5984, -- David Trezeguet
    6235, -- Nedved
    6975, -- Fredrik Ljungberg
    7289, -- Rio Ferdinand
    7512, -- Crespo
    7518, -- Juan Sebastian Veron
    7763, -- Andrea Pirlo
    7826, -- Robin Van Persie
    7854, -- Sergio Conceicao
    8385, -- Aleksandr Mostovoi
    8885, -- Mauricio Pochettino
    9676, -- Samuel Etoo
    10264, -- Ruud Van Nistelrooy
    10535, -- Xavi
    10974, -- Mauricio Pellegrino
    11141, -- Miroslav Klose
    13038, -- Carles Puyol
    13128, -- Andriy Shevchenko
    13383, -- Hidetoshi Nakata
    13743, -- Steven Gerrard
    16619, -- Ivan Cordoba
    20775, -- Ricardo Quaresma
    20801, -- Cristiano Ronaldo
    23174, -- Juanroman Riquelme
    24630, -- Pepe Reina
    26520, -- Alex Hunter Kid
    26521, -- Gareth Walker Kid
    26537, -- Generic Manager
    26538, -- Generic Manager
    26539, -- Generic Manager
    26540, -- Generic Manager
    26541, -- Generic Manager
    26542, -- Generic Manager
    26543, -- Generic Manager
    26544, -- Generic Manager
    26545, -- Generic Manager
    26546, -- Generic Manager
    26547, -- Generic Manager
    26551, -- Generic Boy
    26552, -- Generic Boy
    26553, -- Generic Boy
    26555, -- Generic Boy
    26597, -- Aadila Dosani
    26598, -- Naiah Cummins
    26599, -- Alex Gullason
    26600, -- Renan Diaz
    26601, -- Generic Boy
    26602, -- Generic Boy
    26621, -- Young Girl
    26626, -- Bea
    26635, -- Generic Female
    26636, -- Generic Female
    26638, -- Generic Female
    26639, -- Generic Female
    26640, -- Generic Female
    26641, -- Generic Male
    26642, -- Generic Male
    26643, -- Generic Male
    26644, -- Generic Male
    26645, -- Generic Male
    26646, -- Generic Male
    26647, -- Generic Male
    26648, -- Generic Male
    26650, -- Generic Male
    26651, -- Generic Male
    26669, -- Generic Male
    26670, -- Thierry Henry
    26688, -- Generic Boy
    26689, -- Generic Boy
    26690, -- Generic Boy
    26691, -- Generic Boy
    26692, -- Generic Girl
    26693, -- Generic Girl
    26694, -- Generic Girl
    26695, -- Generic Girl
    26697, -- Generic Girl
    26700, -- Cold Open Referee
    26701, -- Cold Open Referee
    26702, -- Cold Open Referee
    27000, -- Sydney Ko
    27001, -- Bobbi Pillay
    27002, -- Peter Jepsen
    27003, -- Big T
    27004, -- Jason Quezada
    27005, -- Ismail Hamadoui
    27006, -- Edward Vangils
    27007, -- Rocky Hehakaija
    27008, -- Kotaro Tokuda
    27017, -- Dj
    27018, -- Ricardo Kaka
    27026, -- Male Vlogger
    27028, -- Stargeneric Cahn Nguyen
    27029, -- Stargeneric Joe Daru
    27030, -- Stargeneric Perry Lee
    27031, -- Stargeneric Martin Chan
    27032, -- Robert Regpala
    27033, -- Stargeneric Bob Rajwani
    27034, -- Stargeneric Ranjit Samra
    27035, -- Fabian Gujral
    27036, -- Stargeneric Tylan Essery
    27037, -- Stargeneric Ben Herman
    27050, -- Stargeneric Emmanuel Addo
    27051, -- Stargeneric Filipe Camara De Oliviera
    27067, -- Stargeneric Robin Esrock
    27068, -- Stargeneric Theo Irie
    27069, -- Stargeneric Donavon Marshall
    27070, -- Stargeneric Nicholas Ugoalah
    27071, -- Stargeneric Sven Winter
    27072, -- Stargeneric Michael Dahlen
    27073, -- Stargeneric Joel Garcia
    27074, -- Stargeneric Cameron Grierson
    27075, -- Stargeneric Ryo Hayashida
    27076, -- Stargeneric Quentin Nanou
    27077, -- Stargeneric Leonardo Samuel
    27078, -- Stargeneric Ron Wear
    27079, -- Stargeneric Clint Andrew
    27080, -- Stargeneric Alex Chronakis
    27081, -- Stargeneric Dan Hassler
    27082, -- Stargeneric Kurt Moses
    27083, -- Stargeneric Jordon Narvratil
    27084, -- Stargeneric Alex Pleger
    27085, -- Stargeneric Alec Santos
    27086, -- Stargeneric Sophia Billing
    27087, -- Stargeneric Nairelin Manzueta
    27088, -- Stargeneric Raya Meacham
    27089, -- Stargeneric Kourtney Pankuch
    27090, -- Stargeneric Victoria Sealy
    27091, -- Stargeneric Aletheia Urstad
    27092, -- Stargeneric Wayne Bernard
    27093, -- Stargeneric Brad Ignis
    27094, -- Generic Manager
    27095, -- Generic Manager
    27096, -- Generic Manager
    27099, -- Stargeneric James Maitland
    27102, -- Male Agent
    27103, -- Male Assistmanager
    27105, -- Male Assistmanager
    27106, -- Stargeneric Amir Mohebbi
    27108, -- Stargeneric Mohammed Rasheed
    27109, -- Stargeneric Yuri Shamsin
    27110, -- Stargeneric Thomas Strumpski
    27111, -- Stargeneric Nathan Cheung
    27112, -- Stargeneric James R Cowley
    27113, -- Stargeneric Stanley Jung
    27114, -- Stargeneric Yujiro Saga
    27115, -- Stargeneric Jacky Weng
    27201, -- Female Vlogger
    27202, -- Female Assistmanager
    27262, -- Mean Female
    27263, -- Mean Male
    28130, -- Ronaldinho
    31432, -- Didier Drogba
    34079, -- Ashley Cole
    37576, -- Ronaldo
    40003, -- Stargeneric Romeo Fabian
    40005, -- Stargeneric Craig Geoghan
    40007, -- Stargeneric Graham Jenkins
    40010, -- Stargeneric Patrick Perlaky
    40011, -- Stargeneric Nathan Peterson
    40015, -- Stargeneric Peyton Albrecht
    40016, -- Stargeneric Michael Carranza
    40019, -- Stargeneric Jonathan Fernandez
    40020, -- Stargeneric Brandon Finn
    40022, -- Stargeneric Daniel Jordan
    40024, -- Stargeneric Rowan Nasser
    40026, -- Stargeneric Michael Tarik
    40027, -- Stargeneric Christopher Valente
    40028, -- Stargeneric Spencer Vaughn Kelly
    40029, -- Stargeneric Zachary Zaret
    40030, -- Stargeneric Amado Geraldo Ancheta
    40031, -- Stargeneric Marc Le Blanc
    40032, -- Stargeneric Lachlan Quarmby
    40033, -- Stargeneric Michael Sech
    40034, -- Stargeneric Kurt Szarka
    40035, -- Stargeneric Kevin Kokoska
    40036, -- Stargeneric Raymond Johnson Brown
    40037, -- Stargeneric Delali Ayivor
    40038, -- Stargeneric Jide Ajide
    40039, -- Stargeneric A J Crivello Jones
    40040, -- Stargeneric Charlie Nesbit
    40041, -- Stargeneric Christian Daniel Echegoyen
    40042, -- Stargeneric Cyrus Baylis
    40043, -- Stargeneric Ted Stuart
    40044, -- Stargeneric Nader Al Houh
    40045, -- Stargeneric John Connolly
    40046, -- Stargeneric Samuel Curry
    40047, -- Stargeneric Christopher Flint
    40048, -- Stargeneric Zavien Garrett
    40049, -- Stargeneric Gabriel Marshell
    40050, -- Stargeneric Trey Denzyl Stoxx
    40051, -- Stargeneric Daniel Hanuse
    40052, -- Stargeneric Massimo Frau
    40053, -- Stargeneric Michael Danell
    40054, -- Stargeneric Raphael Lecat
    40055, -- Stargeneric Cody Mac Eachern
    40056, -- Stargeneric Prince Nii Engmann
    40057, -- Stargeneric Addison Tessema
    40058, -- Stargeneric Tristan Arthus
    40059, -- Stargeneric Guilherme Babilonia
    40060, -- Stargeneric Scott Button
    40061, -- Stargeneric Evan Green
    40062, -- Stargeneric Charlie Hughes
    40063, -- Stargeneric Joel Mc Veagh
    40064, -- Stargeneric Evan Rein
    40065, -- Stargeneric Jerome Blake
    40066, -- Stargeneric Henry King
    40067, -- Stargeneric Shane Symons
    40068, -- Stargeneric Trevar Fox
    40069, -- Stargeneric Jarod Marcil
    40070, -- Stargeneric Alejandro Herrera Gil
    40071, -- Stargeneric Anthony Bitonti
    40072, -- Stargeneric Marcio Mikael Barauna Araujo
    40073, -- Stargeneric Tyson L W Geick
    40074, -- Stargeneric Gabriel Hildreth
    40075, -- Stargeneric Spencer Irwin
    40076, -- Stargeneric Carlo Latonio
    40077, -- Stargeneric Logan William Tarasoff
    40078, -- Stargeneric Nick Thorp
    40079, -- Stargeneric Ethan Nolan
    40080, -- Stargeneric Frankie Cena
    40081, -- Stargeneric Michael Bortolin
    40082, -- Stargeneric Niko Koupantsis
    40083, -- Stargeneric Robert Byron
    40084, -- Stargeneric Rodney Bourassa
    40085, -- Stargeneric Alec Shaw
    40086, -- Stargeneric Allen David Weins
    40087, -- Stargeneric Levi Wall
    40088, -- Stargeneric Michael Brian
    40089, -- Stargeneric Oliver Castillo
    40091, -- Stargeneric Rich Munton
    40092, -- Stargeneric Brent Yoshesda
    40093, -- Stargeneric Nick Puya
    40400, -- Generic Male
    40401, -- Generic Male
    40402, -- Stargeneric Chris Granlund
    40403, -- Stargeneric Dylan Flynn
    40404, -- Stargeneric Elvis Rivera
    40405, -- Stargeneric Jamal Quezaire
    40406, -- Stargeneric Jesse James
    40407, -- Stargeneric Jesse Vasquez
    40408, -- Stargeneric Karlo Mamic
    40410, -- Stargeneric Krish Lohita
    40411, -- Stargeneric Valentinetuimasev Taylor
    40412, -- Stargeneric Arlo Sarinas
    40413, -- Stargeneric Bradforda Wilson
    40414, -- Stargeneric Brian Kachelmeyeer
    40415, -- Stargeneric Bryanmichael King
    40417, -- Stargeneric Dominque Price
    40418, -- Stargeneric Jamaal Lewis
    40419, -- Stargeneric Juanfelipej Restrepo
    40420, -- Stargeneric Mao Sun
    40423, -- Stargeneric Adam Pepper
    40427, -- Stargeneric Blake Frampton
    40430, -- Stargeneric Dashiell Mcallan
    40431, -- Stargeneric Deyonte Davis
    40432, -- Stargeneric Ellise Fowler
    40433, -- Stargeneric Ivan Thompson
    40434, -- Stargeneric Jay Ellis
    40436, -- Stargeneric Johnny Glasser
    40437, -- Stargeneric Johnathan Diaz
    40438, -- Stargeneric Jorge Gasper
    40439, -- Stargeneric Julian David
    40441, -- Stargeneric Karim Benz
    40442, -- Stargeneric Lee Charm
    40443, -- Stargeneric Widson Harlemont
    40446, -- Stargeneric Tony Do
    40448, -- Stargeneric Tyrone Emanuel
    40450, -- Stargeneric Raheem Lee
    40451, -- Stargeneric Rice Franklin
    40453, -- Stargeneric Robertsteven Blair
    40454, -- Stargeneric Sammy Cantu
    40455, -- Stargeneric Paul Braun
    40456, -- Stargeneric Michael Davis
    40457, -- Stargeneric Rob Bristow
    40458, -- Stargeneric Mike Dirks
    40459, -- Stargeneric Daniel Fox
    40460, -- Stargeneric Marc Noble
    40750, -- Stargeneric Cindy Alvarez
    40751, -- Stargeneric Ghazal Azarbad
    40752, -- Stargeneric Angela Cooper
    40753, -- Stargeneric Alejandra Martinez
    40755, -- Stargeneric Fatima Namatovu
    40756, -- Stargeneric Kelly Brock
    40757, -- Stargeneric Hala Elia
    40758, -- Stargeneric Karina Kunzo
    40759, -- Stargeneric Genevieve Soo
    40760, -- Stargeneric Angela Umeh
    41236, -- Zlatan Ibrahimovic
    44897, -- Jerzy Dudek
    45119, -- Mikel Arteta
    45186, -- Joaquin
    45197, -- Xabi Alonso
    45490, -- Javier Calleja
    45661, -- Raul
    45674, -- Michael Essien
    48745, -- Fabricio Coloccini
    48940, -- Petr Cech
    49000, -- Allan Mcgregor
    49369, -- Fernando Torres
    50542, -- Jermaine Defoe
    51404, -- Sean Dyche
    51412, -- Tim Cahill
    51539, -- Van Der Sar
    52241, -- Larsson
    52326, -- Eldin Jakupovic
    53739, -- Lee Grant
    53769, -- Luis Anderson De Souza
    53914, -- Phil Jagielka
    54033, -- Tom Huddleston
    54050, -- Wayne Rooney
    104389, -- Rune Jarstein
    105846, -- Artur Boruc
    108061, -- Reto Ziegler
    120274, -- Antonio Dinatale
    120533, -- Pepe
    121939, -- Philipp Lahm
    121944, -- Bastien Schweinsteiger
    124635, -- Mehmet Topal
    134779, -- Jimmy Briand
    135043, -- Anders Lindegaard
    135507, -- Fernandinho Luiz Roza
    135587, -- Niki Maenpaa
    135742, -- Alexis Ruano
    135804, -- Sergio Gonzalez
    138412, -- James Milner
    138449, -- Kaka
    138956, -- Giorgio Chiellini
    139062, -- Willy Caballero
    139068, -- Nani
    139720, -- Vincent Kompany
    139860, -- Jeremy Morel
    140196, -- Yasuhito Endo
    140233, -- Guillermo Ochoa
    140293, -- Antonio Mirante
    140601, -- Nemanja Vidic
    142707, -- Lisandro Lopez
    142822, -- Jonas Gutierrez
    143076, -- Alejandro Gomez
    143745, -- Arda Turan
    146296, -- Andres Fernandez
    146439, -- Alvaro Negredo
    146530, -- Dani Alves
    146536, -- Jesus Navas
    146748, -- Diego Lopez
    146758, -- Roberto Soldado Rillo
    146777, -- Michel Sanchez
    146947, -- Mikel Vesga
    146952, -- Ivan Cuellar
    148119, -- Igor Akinfeev
    149791, -- Wes Hoolahan
    150418, -- Mario Gomez
    150516, -- Lukas Podolski
    150527, -- Ralph Hasenhuttl
    150724, -- Joe Hart
    151508, -- Steven Davis
    152554, -- Gael Clichy
    152567, -- Alexander Tettey
    152729, -- Gerard Pique
    152747, -- Aaron Lennon
    152879, -- Mark Noble
    152908, -- Ashley Young
    152996, -- Per Ciljan Skjelbred
    152997, -- Daro Cvitanich
    153079, -- Sergio Aguero
    153244, -- Pierre Andre Gignac
    154950, -- Yuriy Zhirkov
    155355, -- Lee Chung Yong
    155862, -- Sergio Ramos Garcia
    155885, -- Aiden Mcgeady
    155887, -- Michael Bradley
    155897, -- Clint Dempsey
    155946, -- Robert Snodgrass
    155976, -- Charlie Adam
    156320, -- Graham Potter
    156321, -- Adebayo Akinfenwa
    156353, -- Luis Hernandez
    156432, -- Hoarau
    156519, -- Hector Herrera
    156616, -- Franck Ribery
    157301, -- Ryan Babel
    157304, -- Thomas Vermaelen
    157481, -- Raul Albiol Tortajada
    157665, -- Scott Dann
    157703, -- Uwe Hunemeier
    157804, -- Scott Carson
    158023, -- Lionel Messi
    158133, -- Jefferson Farfan
    158543, -- Oribe Peralta
    158625, -- Dante
    158626, -- Debuchy Mathieu
    158810, -- Gokhan Inler
    159034, -- Steven Taylor
    159145, -- Bafetimbi Gomis
    159261, -- Fabio Quagliarella
    160292, -- Ben Watson
    161648, -- Hatem Ben Arfa
    161754, -- Javi Garcia
    161805, -- Valon Behrami
    161840, -- Fernando Hierro
    162240, -- Moussa Dembele
    162329, -- Karim Elahmadi
    162347, -- Joao Moutinho
    162835, -- Samir Handanovic
    162895, -- Fabregas Francesc
    162993, -- James Perch
    163050, -- Billy Sharp
    163155, -- Ben Foster
    163261, -- Phil Bardsley
    163264, -- Tom Heaton
    163303, -- Glenn Whelan
    163587, -- Kasper Schmeichel
    163600, -- John Ruddy
    163705, -- Steve Mandanda
    163761, -- Curtis Davies
    164240, -- Thiago Emiliano Da Silva
    164376, -- Graziano Pelle
    164459, -- Sebastian Larsson
    164464, -- Bradley Wright Phillips
    164468, -- Gary Cahill
    164505, -- Brad Guzan
    164529, -- Drew Moor
    164769, -- Steven Fletcher
    164835, -- Lukasz Fabianski
    164853, -- Adam Federici
    164859, -- Theo Walcott
    164959, -- Stephane Mbia
    164994, -- Jakub Blaszczykowski
    165153, -- Karim Benzema
    165191, -- Cameron Jerome
    165229, -- Laurent Koscielny
    165321, -- Stephen Ward
    165517, -- Fernando Gago
    165889, -- Park Ju Young
    166074, -- Tiago Correia
    166124, -- Gheorghe Hagi
    166149, -- Hugo Sanchez
    166844, -- Kyle Lafferty
    166847, -- Chris Mccann
    166906, -- Franco Baresi
    167135, -- Carlos Alberto
    167198, -- Eric Cantona
    167397, -- Falcao Garcia
    167425, -- Abedi Pele
    167431, -- Gonzalo Castro
    167495, -- Manuel Neuer
    167524, -- Jorge Torresnilo
    167664, -- Gonzalo Higuain
    167665, -- Nicolas Domingo
    167669, -- Federico Higuain
    167680, -- Ronald Koeman
    167925, -- Joey Obrien
    167931, -- Rob Elliot
    167948, -- Hugo Lloris
    168435, -- Salvatore Sirigu
    168542, -- David Silva
    168651, -- Ivan Rakitic
    168886, -- Sami Aljaber
    169078, -- Luke Freeman
    169214, -- Scott Sinclair
    169216, -- Shane Long
    169345, -- Markus Suttner
    169416, -- Carlos Vela
    169426, -- Antonio Barragan Fernandez
    169586, -- Fraizer Campbell
    169588, -- Jonny Evans
    169595, -- Danny Rose
    169596, -- Ryan Shawcross
    169600, -- Danny Simpson
    169638, -- Charlie Daniels
    169697, -- Darren Randolph
    169705, -- Ryan Bertrand
    169706, -- Jack Cork
    169708, -- Sam Hutchinson
    169710, -- Liam Bridcutt
    169792, -- Jay Rodriguez
    169808, -- Urby Emmanuelson
    169894, -- Pep Guardiola
    170008, -- Ben Hamer
    170084, -- Wayne Hennessy
    170368, -- Erik Lamela
    170472, -- Jonathan Parr
    170597, -- Tim Krul
    170719, -- Diego Buonanotte
    170797, -- Nuri Sahin
    170879, -- Shaun Macdonald
    170890, -- Blaise Matuidi
    170941, -- Javier Moyano
    171018, -- Mario Suarez
    171378, -- Paul Aguilar
    171579, -- Raul Garcia
    171791, -- Jose Fonte
    171831, -- Michael Mancienne
    171833, -- Daniel Sturridge
    171877, -- Marek Hamsik
    171896, -- Hugo Ayala
    171897, -- Jose Andres Guardado
    171972, -- James Mcarthur
    172013, -- Alberto De La Bella
    172049, -- Eljero Elia
    172114, -- Diego Valeri
    172143, -- Lasse Schone
    172175, -- Kevin Mirallas
    172203, -- Fraser Forster
    172316, -- Jorge Andujar Moreno
    172425, -- Souleymane Bamba
    172522, -- Daniel Wass
    172553, -- Jonas Lossl
    172723, -- Asmir Begovic
    172862, -- Niklas Moisander
    172871, -- Jan Vertonghen
    172879, -- Sokratis Papastathopoulos
    172904, -- Lee Tomlin
    172960, -- Lewis Grabban
    172962, -- Victor Moses
    173030, -- Oscar Trejo
    173337, -- Yasuyuki Konno
    173373, -- Sergio Romero
    173426, -- Simon Mignolet
    173432, -- Hector Moreno
    173434, -- Pablo Barrera
    173521, -- Ivan Marcano
    173530, -- Sone Aluko
    173533, -- David Button
    173546, -- James Tomkins
    173608, -- Joselu
    173673, -- Stephen Quinn
    173731, -- Gareth Bale
    173735, -- Neil Taylor
    173859, -- Sam Baldock
    173909, -- Kevin Prince Boateng
    174543, -- Claudio Bravo
    175092, -- Maynor Figueroa
    175314, -- Kevin Mcdonald
    175379, -- Pedro Leon
    175895, -- Vadis Odjidja Ofoe
    175943, -- Dries Mertens
    176062, -- Sacha Kljestan
    176237, -- Jozy Altidore
    176266, -- Leiva Pezzini
    176285, -- Winston Reid
    176345, -- Sun Tae Kwoun
    176348, -- Yeom Ki Hun
    176376, -- Ignacio Piatti
    176389, -- Sung Ryong Jung
    176481, -- Mevlut Erding
    176550, -- David Ospina
    176580, -- Luis Suarez
    176600, -- Kevin Gameiro
    176635, -- Mesut Ozil
    176676, -- Marcelo
    176733, -- Marcus Berg
    176841, -- Lukas Jutkiewicz
    176919, -- Nahuel Guzman
    176930, -- Marcelo Diaz
    176944, -- Marouane Fellanini
    176993, -- Bojan Krkic
    177003, -- Luka Modric
    177134, -- Demba Ba
    177138, -- Ilsinho Pereira
    177326, -- Mathieu Valbuena
    177358, -- Morgan Schneiderlin
    177388, -- Dimitri Payet
    177413, -- Axel Witsel
    177448, -- Gustav Svensson
    177578, -- Sebastian Proedl
    177604, -- Nacho Monreal
    177605, -- Jon Erice
    177644, -- Kiko Casilla
    177683, -- Yann Sommer
    177723, -- Fabricio Agosto
    177766, -- Gaetan Bong
    177896, -- Mario Vrancic
    177922, -- Kamil Grosicki
    178005, -- Rui Patricio
    178031, -- Paul Baysse
    178086, -- Adan Garrido
    178088, -- Juan Mata
    178091, -- Stefano Okaka
    178213, -- Etienne Capoue
    178224, -- Javier Hernandez
    178250, -- Papakouli Diop
    178287, -- Scott Arfield
    178322, -- Miguel Layun
    178509, -- Olivier Giroud
    178518, -- Radja Nainggolan
    178562, -- Ever Banega
    178566, -- Javier Garcia
    178567, -- Erik Pieters
    178603, -- Mat Hummels
    178609, -- Marco Silva
    178616, -- Adrian Gonzalez
    178625, -- Pedro Mosquera
    179516, -- Rouwen Hennings
    179527, -- Loic Remy
    179546, -- Marko Marin
    179547, -- Vito Mannone
    179551, -- Ola Kamara
    179591, -- Pablo Hernandez Dominguez
    179605, -- Adel Taarabt
    179645, -- Simon Kjaer
    179685, -- Chris Seitz
    179731, -- David Cabrera
    179746, -- Sam Vokes
    179783, -- Ralf Fahrmann
    179813, -- Edinson Cavani
    179844, -- Diego Costa
    179847, -- Federico Fazio
    180175, -- Alexandre Pato
    180206, -- Pjanic Miralem
    180216, -- Seamus Coleman
    180283, -- Ki Sung Yueng
    180334, -- Marcelo Guedes
    180403, -- Willian
    180706, -- Craig Cathcart
    180739, -- Eiji Kawashima
    180818, -- David Mc Goldrick
    180819, -- Adam Lallana
    180930, -- Edin Dzeko
    181098, -- Makoto Hasebe
    181291, -- Georginio Wijnaldum
    181318, -- Albin Ekdal
    181458, -- Ivan Perisic
    181820, -- Stevan Jovetic
    181872, -- Arturo Vidal
    182002, -- Sidnei Da Silva Junior
    182168, -- Andrea Ranocchia
    182184, -- Dale Stephens
    182435, -- Mitch Langerak
    182493, -- Diego Godin
    182521, -- Toni Kroos
    182761, -- Adam Legzdins
    182763, -- Nikica Jelavic
    182836, -- Andy Carroll
    182888, -- Havard Nordtveit
    182945, -- Max Gradel
    183108, -- Nordin Amrabat
    183125, -- Troy Deeney
    183129, -- Ciaran Clark
    183130, -- Marc Albrighton
    183141, -- Oier Olazabal
    183187, -- Valentin Stocker
    183277, -- Eden Hazard
    183280, -- Adil Rami
    183285, -- Mamadou Sakho
    183339, -- Jo Inge Berget
    183385, -- Adlene Guedioura
    183394, -- Moussa Sissoko
    183422, -- Jonny Howson
    183427, -- Fabian Delph
    183465, -- Jack Rodwell
    183491, -- Mathias Jorgensen
    183497, -- Orestis Karnezis
    183512, -- Yuri Berchiche
    183518, -- Rui Fonte
    183520, -- Fran Merida
    183540, -- Barry Bannan
    183546, -- Jonathan Hogg
    183549, -- Elliot Parish
    183569, -- Eric Choupo Moting
    183574, -- Max Kruse
    183580, -- Nils Petersen
    183581, -- Jesus Molina
    183617, -- Slaven Bilic
    183622, -- Joachim Low
    183632, -- Robert Tesche
    183666, -- Roberto Jimenez
    183711, -- Jordan Henderson
    183714, -- Simon Terodde
    183774, -- Ryan Bennett
    183795, -- Georg Margreitter
    183855, -- Angelo Ogbonna
    183893, -- Claudio Yacob
    183895, -- Maxi Moralez
    183898, -- Angel Di Maria
    183899, -- Pablo Piatti
    183900, -- Diego Perotti
    183907, -- Jerome Boateng
    183940, -- Vurnon Anita
    184037, -- Martin Kelly
    184087, -- Toby Alderweireld
    184111, -- Christian Benteke
    184134, -- Fernando Francisco Reges
    184144, -- Nicolas Gaitan
    184200, -- Marko Arnautovic
    184274, -- Chris Basham
    184344, -- Leonardo Bonucci
    184392, -- Matteo Darmian
    184431, -- Sebastian Giovinco
    184432, -- Cesar Azpilicueta
    184436, -- Alex Smithies
    184467, -- Nathan Delfouneso
    184469, -- Harry Arter
    184472, -- Martin Olsson
    184477, -- Kyriakos Papadopoulos
    184480, -- Hal Robson Kanu
    184484, -- Gylfi Sigurdsson
    184501, -- Michael Lang
    184575, -- Romain Alessandrini
    184624, -- Jordan Rhodes
    184630, -- Luke Daniels
    184664, -- Aurelien Collin
    184716, -- Joe Allen
    184749, -- Dan Gosling
    184826, -- Adrien Silva
    184881, -- Sofiane Feghouli
    184941, -- Alexis Sanchez
    184990, -- Antonio Regal
    185010, -- Michal Pazdan
    185020, -- Jose Callejon
    185068, -- Johnny Russell
    185103, -- Aleksandar Kolarov
    185122, -- Peter Gulacsi
    185132, -- Mikel San Jose
    185181, -- Yoel Rodriguez
    185195, -- Odion Ighalo
    185221, -- Luiz Gustavo Dias
    185239, -- Omer Toprak
    185349, -- Denis Odoi
    185422, -- Joshua King
    185427, -- Orjan Nyland
    186115, -- Keiran Gibbs
    186116, -- Henri Lansbury
    186117, -- Jordon Mutch
    186130, -- James Chester
    186132, -- Danny Drinkwater
    186139, -- Matty James
    186143, -- Oliver Norwood
    186146, -- Danny Welbeck
    186148, -- Ron Robert Zieler
    186153, -- Wojciech Szczesny
    186156, -- Luke Ayling
    186158, -- Kyle Bartley
    186190, -- Patrick Van Aanholt
    186197, -- Gael Kakuta
    186200, -- Fabio Borini
    186307, -- Marco Fabian
    186345, -- Kieran Trippier
    186351, -- Leroy Fer
    186385, -- Adam Clayton
    186392, -- Joel Ward
    186395, -- Matt Ritchie
    186452, -- Siem Dejong
    186521, -- Bernardo Espinosa
    186537, -- Christian Stuani
    186561, -- Aaron Ramsey
    186569, -- Sven Ulreich
    186578, -- Andy King
    186595, -- Elliott Bennett
    186598, -- Kyle Naughton
    186627, -- Balotelli
    186672, -- Geoff Cameron
    186674, -- Roger Espinoza
    186680, -- Raul Fernandez
    186684, -- Kiko Olivas
    186695, -- Ezequiel Munoz
    186715, -- Shea Salinas
    186783, -- Albert Adomah
    186801, -- Cheikhou Kouyate
    186805, -- Jefferson Montero
    186905, -- Ashley Barnes
    186942, -- Ilkay Gundogan
    186961, -- Alberto Paloschi
    186992, -- Jesus Duenas
    187033, -- Sean Morrison
    187043, -- Stefan Johansen
    187072, -- Lars Stindl
    187084, -- Mame Diouf
    187110, -- Miguel Ponce
    187208, -- Alfredo Saldivar
    187735, -- Alan Dzagoev
    187936, -- Steven Nzonzi
    187961, -- Paulinho
    188038, -- Ondrej Celustka
    188041, -- Rafael Carioca
    188135, -- Juan Francisco Moreno Fuertes
    188152, -- Oscar
    188154, -- Lewis Holtby
    188155, -- Daryl Janmaat
    188166, -- Matt Phillips
    188168, -- George Friend
    188182, -- Leon Balogun
    188253, -- James Mccarthy
    188270, -- Bruno Ecuelemanga
    188271, -- Floyd Ayite
    188289, -- Emmanuel Riviere
    188337, -- Mubarak Wakaso
    188350, -- Marco Reus
    188377, -- Kyle Walker
    188388, -- Ryad Boudebouz
    188545, -- Robert Lewandowski
    188567, -- Pierre Emerick Aubameyang
    188657, -- Declan Rudd
    188770, -- Admir Mehmedi
    188802, -- Marcel Schmelzer
    188829, -- Nicolas Nkoulou
    188836, -- Jason Steele
    188879, -- Alfred Ndiaye
    188942, -- Victor Wanyama
    188943, -- Kevin Trapp
    188955, -- Gustavo Bou
    188988, -- Manuel Lanzini
    189043, -- Daniel Brosinski
    189059, -- Jake Livermore
    189060, -- Aleksandar Dragovic
    189084, -- Eloy Room
    189117, -- Roman Burki
    189148, -- Jamie Murphy
    189156, -- Daniel Carrico
    189157, -- Yannick Bolasie
    189165, -- Jonjo Shelvey
    189167, -- Aron Gunnarsson
    189177, -- John Fleck
    189234, -- Marcel Risse
    189242, -- Philippe Coutinho
    189250, -- Salomon Rondon
    189271, -- Francis Coquelin
    189280, -- Ashley Westwood
    189303, -- Nelson Oliveira
    189324, -- Alex Mccarthy
    189332, -- Jordi Alba Ramos
    189357, -- Cristopher Toselli
    189358, -- Kagawa
    189388, -- Dennis Diekmeier
    189390, -- Bastian Oczipka
    189403, -- Nathan Baker
    189410, -- Danny Latza
    189433, -- Benjamin Hubner
    189446, -- Junior Stanislas
    189456, -- Liam Cooper
    189462, -- Junior Hoilett
    189484, -- Davide Santon
    189505, -- Pedro
    189506, -- Victor Sanchez
    189509, -- Thiago Alcantara
    189511, -- Sergio Busquets
    189513, -- Daniel Parejo Munoz
    189514, -- Harrison Afful
    189560, -- Vicente Iborra
    189575, -- Iker Muniain Goni
    189576, -- Jonas Ramalho
    189596, -- Thomas Muller
    189606, -- Julian Baumgartlinger
    189615, -- Aaron Cresswell
    189655, -- Zdenek Ondrasek
    189680, -- Fabio Pereira Da Silva
    189681, -- Rafael Pereira Da Silva
    189682, -- Ben Mee
    189690, -- Vicente Guaita Panadero
    189709, -- Pedro Alcala
    189712, -- Kevin Strootman
    189725, -- Tom Cleverley
    189805, -- Luuk De Jong
    189860, -- Francisco Femenia
    189881, -- Chris Smalling
    189899, -- Vito Wormgoor
    189945, -- Yoric Ravet
    189963, -- Wilfried Bony
    190034, -- Thimothee Kolodzieczak
    190042, -- Diego Maradona
    190044, -- Bobby Moore
    190045, -- Johan Cruyff
    190046, -- Socrates
    190049, -- Eusebio
    190053, -- Peter Schmeichel
    190059, -- Steven Zuber
    190149, -- Oscar De Marcos
    190156, -- Ruben Perez
    190223, -- Mikel Balenziaga
    190243, -- Marwin Hitz
    190264, -- Silva Lago
    190286, -- Sergio Canales Madrazo
    190324, -- Christian Kabasele
    190362, -- Teemu Pukki
    190430, -- Joe Bennett
    190456, -- Nathaniel Clyne
    190460, -- Christian Eriksen
    190507, -- Xabier Etxeita
    190520, -- Tony Jantschke
    190531, -- Eliaquim Mangala
    190535, -- Michel Herrero
    190547, -- Kamil Glik
    190549, -- Markus Henriksen
    190557, -- Graham Zusi
    190558, -- Ike Opara
    190560, -- Omar Gonzalez
    190569, -- Stefan Frei
    190584, -- Asier Illarramendiandonegui
    190653, -- Isaac Brizuela
    190666, -- Manuel Gulde
    190671, -- Mike Frantz
    190717, -- Michail Antonio
    190720, -- Tosaint Ricketts
    190738, -- Havard Nielsen
    190752, -- Jan Kirchhoff
    190765, -- Pascal Grob
    190772, -- Matt Besler
    190780, -- Sean Johnson
    190782, -- Sandro
    190793, -- Haris Vuckic
    190813, -- Stephan Shaarway
    190815, -- Daley Blind
    190824, -- Omar Elabdellaoui
    190852, -- Callum Mcmanaman
    190871, -- Neymar
    190885, -- Adam Smith
    190919, -- Fredy Montero
    190941, -- Lukas Hradecky
    191032, -- Gokhan Tore
    191043, -- Alex Sandro Lobo Silva
    191053, -- Tomas Rincon
    191055, -- Vila Didac
    191076, -- Johann Berg Gudmondsson
    191089, -- Connor Wickham
    191173, -- Alejandro Bedoya
    191180, -- Javier Pastore
    191189, -- Lothar Matthaus
    191202, -- Nemanja Matic
    191210, -- Sebastien Corchia
    191269, -- Salman Al Faraj
    191378, -- Shu Kurata
    191388, -- Takashi Usami
    191488, -- Lucas Orban
    191556, -- Yasushi Endo
    191565, -- Yuya Osako
    191648, -- Mayo Yoshida
    191655, -- Kim Seung Gyu
    191694, -- Jorge Campos
    191695, -- Emilio Butragueno
    191740, -- Ander Herrera
    191972, -- David Ginola
    191980, -- Yun Suk Young
    192012, -- Diego Reyes
    192045, -- Luis Rodriguez
    192114, -- Antonio Briseno
    192119, -- Thibaut Courtois
    192123, -- Chris Wood
    192129, -- Kristoffer Nordfeldt
    192181, -- Van Basten
    192227, -- Shkodran Mustafi
    192317, -- Jed Steer
    192318, -- Mario Gotze
    192319, -- Luke Garbutt
    192350, -- Javier Aquino
    192366, -- Nicolas Otamendi
    192387, -- Ciro Immobile
    192445, -- Daniel Ginczek
    192448, -- Marc Stegen
    192449, -- Marco Stiepermann
    192476, -- Andreu Fontas
    192492, -- Fabian Orellana
    192505, -- Romelu Lukaku
    192546, -- Enda Stevens
    192557, -- Marvin Plattenhardt
    192563, -- Bernd Leno
    192565, -- Yunus Malli
    192567, -- Matthias Zimmermann
    192620, -- Holger Badstuber
    192622, -- Shane Duffy
    192629, -- Iago Aspas
    192638, -- Marcos Alonso
    192641, -- Kevin Vogt
    192658, -- Sebastian Jung
    192667, -- Allan Romeo Nyom
    192678, -- Enrique Garcia Martinez
    192679, -- Sergio Escudero
    192715, -- Juan Pe Lopez
    192725, -- Maxime Lemarchand
    192732, -- Edgar Prib
    192774, -- Kostas Manolas
    192789, -- Mario Perez
    192838, -- Ezequiel Schelotto
    192883, -- Henrikh Mkhitaryan
    192922, -- Oscar Jimenez
    192955, -- Mateusz Klich
    192984, -- Koen Casteels
    192985, -- Kevin De Bruyne
    192991, -- Cenk Tosun
    193011, -- Steve Cook
    193041, -- Keylor Navas
    193061, -- Roberto Pereyra
    193062, -- Marvin Zeegelaar
    193080, -- David De Gea
    193082, -- Juan Cuadrado
    193105, -- Alphonse Areola
    193116, -- Maxime Gonalons
    193141, -- Ivan Pillud
    193152, -- Iago Herrerin
    193158, -- Davy Propper
    193165, -- Jesus Corona
    193171, -- Jaume Costa
    193185, -- Scott Malone
    193186, -- Neil Etheridge
    193278, -- Chris Mavinga
    193283, -- Thomas Delaney
    193301, -- Alexandre Lacazette
    193331, -- Karl Darlow
    193338, -- Mattia Destro
    193348, -- Xherdan Shaqiri
    193352, -- Ricardo Rodriguez
    193361, -- Roberto Soriano
    193408, -- Haris Seferovic
    193425, -- Hanno Behrens
    193429, -- Douglas Pereirados Santos
    193440, -- Nick Viergever
    193469, -- Victor Ruiz Torre
    193474, -- Idrissa Gueye
    193475, -- Pape Souare
    193504, -- Steven Caulker
    193554, -- Diafra Sakho
    193561, -- Kelvin Leerdam
    193584, -- Guido Burgstaller
    193698, -- Oliver Baumann
    193747, -- Koke Resurreccion
    193849, -- Conor Hourihane
    193881, -- Filip Duricic
    193886, -- Daniel Didavi
    193910, -- Adam Forshaw
    193942, -- Jack Colback
    194017, -- Andreas Weimann
    194022, -- Andre Almeida
    194138, -- Andre Gray
    194146, -- Kevin Long
    194149, -- Fredrik Ulvestad
    194150, -- Simon Moore
    194163, -- Jukka Raitala
    194201, -- Pontus Jansson
    194222, -- Victor Laguardia
    194229, -- Hugo Mallo
    194319, -- Danny Ward
    194333, -- Rafal Gikiewicz
    194334, -- Daniel Sanchez Ayala
    194359, -- Nagatomo
    194361, -- Tomoaki Makino
    194365, -- Okazaki
    194404, -- Norberto Neto
    194644, -- Martin Montoya
    194665, -- Stefan Ilsanker
    194728, -- Ishak Belfodil
    194761, -- Borja Garcia
    194765, -- Antoine Griezmann
    194794, -- Andriy Yarmolenko
    194806, -- Craig Dawson
    194845, -- Wahbi Khazri
    194879, -- Sergi Enrich
    194904, -- Bill Hamid
    194911, -- Adrian
    194932, -- Andros Townsend
    194957, -- Phil Jones
    194958, -- Aaron Mooy
    194964, -- Nathaniel Mendezlaing
    194996, -- Borja Baston
    195033, -- Mathew Leckie
    195037, -- Danny Batth
    195038, -- Florian Kainz
    195093, -- Willian Jose
    195202, -- Tom Cairney
    195361, -- Javi Lopez
    195363, -- Jeffrey Bruma
    195365, -- Kevin Kampl
    195479, -- James Tavernier
    195586, -- Alfred Finnbogason
    195668, -- Joel Robles
    195671, -- Charlie Austin
    195698, -- Cheick Doukoure
    195859, -- Danny Ings
    195864, -- Paul Pogba
    195912, -- Suk Hyun Jun
    196069, -- Jose Pedro Fuenzalida
    196318, -- Serdar Gurler
    196978, -- Callum Wilson
    197031, -- Marvin Ducksch
    197061, -- Joel Matip
    197083, -- Daniel Caligiuri
    197166, -- Juan Agudelo
    197225, -- Nicolas Lodeiro
    197445, -- David Alaba
    197655, -- Sebastian Coates
    197681, -- Gianelli Imbula
    197716, -- Teal Bunbury
    197756, -- Jordan Ayew
    197774, -- Conor Mcaleny
    197781, -- Francisco Roman Alarcon Suarez
    197837, -- Dedryck Boyata
    197851, -- Akihiro Hayashi
    197853, -- Serge Aurier
    197891, -- Juan Miguel Jimenez Lopez
    197948, -- Florian Lejeune
    197965, -- Pizzi Fernandes
    198000, -- Justin Morrow
    198009, -- Mattia Perin
    198023, -- Ximo Navarro
    198031, -- Sergio Oliveira
    198032, -- Dan Burn
    198077, -- Patrick Herrmann
    198113, -- Marco Hoger
    198118, -- Josuha Guilavogui
    198133, -- Leandro Bacuna
    198140, -- Rogelio Funes Mori
    198141, -- Marc Bartra Aregall
    198150, -- Miguel Angel Guerrero
    198164, -- Jonathan Viera
    198176, -- Stefan De Vrij
    198190, -- Greg Cunningham
    198198, -- Jordi Amat
    198200, -- Benjamin Stambouli
    198219, -- Lorenzo Insigne
    198240, -- Raul Garcia
    198261, -- Tim Ream
    198288, -- Steven Beitashour
    198329, -- Rodrigo Moreno
    198331, -- Matej Vydra
    198335, -- Bryan Oviedo
    198352, -- Stefan Bell
    198368, -- Tomas Pina
    198474, -- Alberto Guitian
    198489, -- James Mcclean
    198614, -- Raul Navas
    198641, -- Kenneth Zohore
    198683, -- Manolo Gabbiadini
    198706, -- Luis Alberto
    198710, -- James Rodriguez
    198715, -- Sergio Leon
    198717, -- Wilfried Zaha
    198719, -- Nathan Redmond
    198760, -- Saphir Taider
    198784, -- Alex Oxlade Chamberlain
    198817, -- Romain Amalfitano
    198843, -- Aday Benitez
    198861, -- Nampalys Mendy
    198904, -- Grant Hanley
    198946, -- Danilo D Ambrosio
    198950, -- Pablo Sarabia
    198951, -- Cedric Bakambu
    198970, -- Jonathan Mensah
    199005, -- Mathew Ryan
    199042, -- Charles Aranguiz
    199069, -- Vincent Aboubakar
    199101, -- Raul Lizoain
    199110, -- Luis Muriel
    199131, -- Anton Tinnerholm
    199157, -- Antonio Luna
    199189, -- Ross Barkley
    199266, -- Ji Dong Won
    199282, -- Amir Abrashi
    199304, -- Danilo Da Silva
    199353, -- Marc Rzatkowski
    199354, -- Lucas Perez
    199383, -- Timm Klose
    199422, -- Jordy Clasie
    199434, -- Dusan Tadic
    199439, -- Michael Gregoritsch
    199451, -- Wissam Ben Yedder
    199482, -- Anthony Lopes
    199487, -- Alejandro Galvez
    199503, -- Granit Xhaka
    199550, -- Bruno Martins Indi
    199556, -- Marco Verratti
    199561, -- Manuel Agudo Duran
    199562, -- Ilie Sanchez
    199564, -- Sergio Roberto Carnicer
    199570, -- Jesus Sanchez
    199575, -- Jordi Masip
    199576, -- Oriol Romeu
    199577, -- Sergi Gomez
    199580, -- Connor Goldson
    199602, -- John Guidetti
    199633, -- Matthew Lowton
    199652, -- Dennis Praet
    199667, -- Ramiro Funes Mori
    199669, -- Leandro Gonzalez Perez
    199692, -- Hiram Mier
    199715, -- Victor Mechin Perez
    199729, -- Daniel Royer
    199761, -- Marcin Kaminski
    199767, -- Marco Van Ginkel
    199779, -- Andre Hoffmann
    199812, -- Ryan Allsop
    199823, -- Jose Campana
    199829, -- David Timor
    199833, -- Lars Unnerstall
    199897, -- Nicolas Hofler
    199914, -- Allan Marques Loureiro
    199915, -- Lewis Dunk
    199952, -- Emre Colak
    199986, -- Anaitz Arbilla
    200054, -- Pedro Obiang
    200067, -- Zakaria Diallo
    200104, -- Heung Min Son
    200145, -- Casemiro
    200212, -- Michael Esser
    200215, -- Sebastian Rode
    200260, -- Steven Berghuis
    200275, -- Youness Mokhtar
    200309, -- Tendayi Darikwa
    200315, -- Christian Tello
    200316, -- Timo Horn
    200318, -- Mark Uth
    200389, -- Jan Oblak
    200408, -- Ben Gibson
    200429, -- Benito Raman
    200454, -- Francisco Alcacer Garcia
    200458, -- Lucas Digne
    200463, -- Tim Melia
    200478, -- Jeff Hendrick
    200519, -- Jorge Pulido
    200521, -- Thomas Ince
    200529, -- Nacer Chadli
    200536, -- Nico Schulz
    200601, -- Yoon Bit Ga Ram
    200607, -- Christopher Schindler
    200610, -- Kevin Volland
    200641, -- Yevhen Konoplyanka
    200647, -- Josip Ilicic
    200700, -- Alexander Merkel
    200724, -- Jose Ignacio Fernandez Iglesias
    200741, -- Tyias Browning
    200746, -- John Lundstram
    200752, -- Juan Guilherme Nunes Jesus
    200758, -- Liam Moore
    200759, -- Jeff Schlupp
    200765, -- Muhamed Besic
    200778, -- Cyrus Christie
    200807, -- Kieron Freeman
    200841, -- Carl Jenkinson
    200855, -- George Baldock
    200857, -- Mortiz Leitner
    200888, -- Danilo Pereira
    200949, -- Lucas Moura
    201024, -- Kalidou Koulibaly
    201093, -- Nick Powell
    201095, -- Agustin Marchesin
    201118, -- Cedric Soares
    201143, -- Aissa Mandi
    201153, -- Morata
    201155, -- Ravel Morrison
    201208, -- Doneil Henry
    201262, -- Vladimir Darida
    201305, -- Gabriel Armando De Abreu
    201368, -- Kenny Mc Lean
    201377, -- Jeison Murillo
    201399, -- Mauro Icardi
    201400, -- Rafael Alcantarado Nascimento
    201403, -- Alvaro Vazquez
    201417, -- Matt Doherty
    201447, -- Sebastian Lletget
    201455, -- Geoffrey Kondogbia
    201491, -- Daniel Lafferty
    201505, -- David Lopez
    201509, -- Juan Carlos
    201510, -- Layvin Kurzawa
    201514, -- Elias Kachunga
    201519, -- Jordan Vertout
    201535, -- Raphael Varane
    201549, -- Nemanja Nikolic
    201818, -- Ahmed Musa
    201858, -- Nicola Sansone
    201860, -- Ermin Bicakcic
    201862, -- Marcos Rojo
    201869, -- Russel Teibert
    201873, -- Joe Bendik
    201884, -- Robbie Brady
    201887, -- Daniel Johnson
    201893, -- Jose Luis Garcia Del Pozo
    201895, -- Diego Fagundez
    201911, -- Will Keane
    201922, -- Martin Hinteregger
    201942, -- Roberto Firmino
    201953, -- Juan Sanchez Mino
    201955, -- Massadio Haidara
    201956, -- Salif Sane
    201971, -- Akihiro Ienaga
    201982, -- Jonathan Schmid
    201988, -- Federico Fernandez
    201995, -- Felipe Anderson
    202017, -- Onel Hernandez
    202048, -- Conor Coady
    202052, -- Benik Afobe
    202054, -- Naldo Naldo
    202073, -- Eriq Zavaleta
    202077, -- Will Bruin
    202078, -- Darlington Nagbe
    202088, -- Felix Klaus
    202107, -- Alfredo Morales
    202113, -- Moses Odubajo
    202126, -- Harry Kane
    202135, -- Stefano Sturaro
    202151, -- Konstantinos Stafylidis
    202166, -- Julian Draxler
    202170, -- Michael Boxall
    202201, -- Jeffrey Gouweleeuw
    202223, -- Justin Meram
    202231, -- Hector Jimenez
    202282, -- Stuart Armstrong
    202316, -- Timmy Chandler
    202325, -- Diego Demme
    202335, -- Eric Dier
    202371, -- Thomas Meunier
    202428, -- Bobby Wood
    202429, -- Danny Dacosta
    202445, -- Rodrigo Ely
    202465, -- Richie Towell
    202477, -- Gerard Deulofeu
    202491, -- Tom Carroll
    202501, -- David Junca
    202515, -- Jese Rodriguez
    202556, -- Memphis Depay
    202648, -- Sergi Darder
    202652, -- Raheem Sterling
    202685, -- Simone Zaza
    202686, -- Nahki Wells
    202695, -- James Tarkowski
    202697, -- Jack Stephens
    202750, -- Willy Boly
    202789, -- Alexander Schwolow
    202811, -- Emiliano Martinez
    202849, -- Jannik Vestergaard
    202851, -- Gregoire Defrel
    202855, -- Long Tan
    202857, -- Karim Bellarabi
    202884, -- Leonardo Spinazzola
    202896, -- Marco Urena
    202935, -- Alvaro Gonzalez Soberon
    202940, -- Neeskens Kebano
    203002, -- Kee Hee Kim
    203030, -- Robin Knoche
    203042, -- Jack Butland
    203067, -- Diego Chara
    203106, -- Leo Bittencourt
    203263, -- Harry Maguire
    203265, -- Tyler Blackett
    203280, -- Valere Germain
    203299, -- Andre Carrillo
    203331, -- Lloyd Isgrove
    203362, -- Mohamed Elyounoussi
    203376, -- Virgil Van Dijk
    203483, -- Davy Klaassen
    203485, -- Terence Kongolo
    203486, -- Thorgan Hazard
    203487, -- Jamaal Lascelles
    203502, -- Bobby Reid
    203505, -- Joe Bryan
    203528, -- Alhassane Bangoura
    203537, -- Sammy Ameobi
    203544, -- Chris Lowe
    203551, -- Alessandro Florenzi
    203570, -- Stuart Dallas
    203574, -- John Stones
    203590, -- Florian Hubner
    203605, -- Pavel Kaderabek
    203725, -- Virgil Misidjan
    203747, -- Hector Bellerin
    203757, -- Ze Luis
    203775, -- Loris Karius
    203783, -- Tommy Smith
    203796, -- Felipe Gutierrez
    203841, -- Nick Pope
    203890, -- Sime Vrsaljko
    203895, -- Alejandro Pozuelo
    203910, -- Anthony Knockaert
    203965, -- Viktor Fischer
    204024, -- Christoph Kramer
    204050, -- Santiago Vergini
    204077, -- Mbaye Niang
    204082, -- John Brooks
    204131, -- Kevin Escamilla
    204136, -- Michael De Leeuw
    204163, -- Jores Okore
    204193, -- Tom Trybull
    204210, -- Florin Gardos
    204215, -- Adam Reach
    204233, -- Charly Musonda
    204246, -- Marcus Bettinelli
    204276, -- Tomer Hemed
    204278, -- David Simon
    204289, -- Saido Berahino
    204307, -- Julian Korb
    204311, -- Kurt Zouma
    204355, -- Paul Dummett
    204366, -- Jurgen Locadia
    204438, -- Clement Diop
    204464, -- Joe Ralls
    204472, -- Bouna Sarr
    204485, -- Riyad Mahrez
    204497, -- Kevin Stoger
    204499, -- Ryan Inniss
    204523, -- Ruben Pardo
    204525, -- Inigo Martinez
    204529, -- Michy Batshuayi Tunga
    204538, -- Raul Ruidiaz
    204539, -- Luis Advincula
    204542, -- Yoshimar Yotun
    204555, -- Ricardo Alvarez
    204638, -- Willi Orban
    204639, -- Stefan Savic
    204677, -- Oriol Rosell
    204709, -- Diego Rubio
    204713, -- Joel Campbell
    204738, -- Renato Ibarra
    204757, -- Antonio Garcia Aranda
    204760, -- Charlie Taylor
    204826, -- Abdoulaye Ba
    204838, -- Raul Jimenez
    204846, -- Jamal Blackman
    204847, -- Todd Kane
    204884, -- Benjamin Mendy
    204923, -- Marcel Sabitzer
    204935, -- Jordan Pickford
    204936, -- John Egan
    204963, -- Daniel Carvajalramos
    204970, -- Florian Thauvin
    205069, -- Juan Bernat Velasco
    205070, -- Christian Portugues
    205114, -- Takashi Inui
    205175, -- Arkadiusz Milik
    205186, -- Paulo Gazzaniga
    205192, -- Denis Suarez
    205193, -- Karim Rekik
    205212, -- David Ferreiro
    205243, -- Molla Wague
    205346, -- Ryan Fredericks
    205351, -- Alex Pritchard
    205360, -- Kemar Roofe
    205361, -- Liam Oneil
    205362, -- Matija Nastasic
    205431, -- Niclas Fullkrug
    205452, -- Antonio Rudiger
    205498, -- Jorginho Filho
    205525, -- Bernard Caldeira
    205566, -- Alberto Moreno
    205569, -- James Ward Prowse
    205590, -- Luis Hernandez
    205600, -- Samuel Umtiti
    205601, -- Christian Atsu
    205670, -- Dwight Gayle
    205693, -- Sebastien Haller
    205705, -- Zouhair Feddal
    205878, -- Stefanos Kapino
    205895, -- Alexander Ring
    205897, -- Nathaniel Chalobah
    205923, -- Ben Davies
    205941, -- Cristian Chavez
    205943, -- Vlad Chiriches
    205976, -- Leo Baptistao
    205985, -- Isaac Kiese Thelin
    205988, -- Luke Shaw
    205989, -- Calum Chambers
    205990, -- Harrison Reed
    205995, -- Jetro Willems
    206003, -- Yvon Mvogo
    206006, -- Ezgjan Alioski
    206058, -- Mattia Sciglio
    206075, -- Sam Johnstone
    206083, -- Josh Murphy
    206085, -- Jacob Murphy
    206086, -- Harry Toffolo
    206113, -- Serge Gnabry
    206115, -- Isaac Hayden
    206152, -- Luciano Aued
    206198, -- Dominique Heintz
    206207, -- Wilfried Zahibo
    206222, -- Pedro Bigas
    206225, -- Denis Cheryshev
    206263, -- Tom Hopper
    206304, -- Luka Milivojevic
    206306, -- Jordan Ferri
    206467, -- Alassane Plea
    206511, -- Maximilian Arnold
    206516, -- Will Hughes
    206517, -- Jack Grealish
    206518, -- Callum Robinson
    206534, -- Patrick Bamford
    206538, -- Kevin Stewart
    206545, -- Manuel Trigueros
    206549, -- Evan Bush
    206562, -- Louis Thompson
    206585, -- Kepa Arrizabalaga
    206590, -- Moi Gomez
    206591, -- Mitchell Weiser
    206594, -- Solly March
    206626, -- Mikael Ishak
    206631, -- Kelyn Rowe
    206652, -- Sergio Rico
    206654, -- Pablo Mari
    206662, -- Matt Hedges
    207410, -- Mateo Kovacic
    207421, -- Leandro Trossard
    207431, -- Pablo Insua
    207439, -- Leandro Paredes
    207441, -- Luciano Vietto
    207465, -- Felipe Martins
    207471, -- Franco Vazquez
    207494, -- Jesse Lingard
    207557, -- Robin Olsen
    207566, -- William Carvalho
    207599, -- Michael Keane
    207616, -- Adam Webster
    207645, -- Modou Barrow
    207650, -- Emil Krafth
    207664, -- Carlos Bacca
    207707, -- Fernando Marcal
    207715, -- Nicolas Lopez
    207725, -- Mike Van Der Hoorn
    207732, -- Roger Marti
    207783, -- Raymon Gaddis
    207790, -- Kaan Ayhan
    207791, -- Yussuf Poulsen
    207807, -- Ryan Fraser
    207858, -- Dom Dwyer
    207862, -- Matthias Ginter
    207863, -- Felipe Monteiro
    207865, -- Marcos Aoas Correa
    207877, -- Josef Martinez
    207894, -- Tobias Strobl
    207920, -- Erik Durm
    207935, -- Matias Dituro
    207939, -- Guido Pizarro
    207948, -- Bertrand Traore
    207993, -- Sead Kolasinac
    207998, -- Danny Ward
    208088, -- Sergi Samper
    208093, -- Gerard Moreno
    208120, -- Kacper Przybylko
    208128, -- Hakan Calhanoglu
    208135, -- Abdoulaye Doucoure
    208141, -- Gabriel Appelt Pires
    208230, -- Andreas Samaris
    208268, -- Bryan Cristante
    208295, -- Romain Saiss
    208309, -- Ibrahima Cisse
    208330, -- Adnan Januzaj
    208333, -- Emre Can
    208334, -- Jonas Hector
    208335, -- Lukas Kubler
    208374, -- Andrew Wooten
    208375, -- Marius Muller
    208418, -- Yannick Carrasco
    208421, -- Saul Niguez
    208448, -- Emil Forsberg
    208450, -- Andreas Pereira
    208451, -- Robin Quaison
    208461, -- Marten De Roon
    208520, -- Hiroki Sakai
    208521, -- Frederic Brillant
    208534, -- Alfie Mawson
    208549, -- Andy Rose
    208574, -- Filip Kostic
    208596, -- Andrea Belotti
    208618, -- Lucas Vazquez
    208620, -- Omar Mascarell
    208621, -- Oscar Plano
    208622, -- Ruben Sobrino
    208668, -- David Henen
    208670, -- Hakim Ziyech
    208722, -- Sadio Mane
    208808, -- Quincy Promes
    208830, -- Jamie Vardy
    208892, -- Sam Byram
    208916, -- Mohammad Al Sahlawi
    208920, -- Nathan Ake
    208949, -- Nawaf Al Abed
    209281, -- Yahya Al Shehri
    209289, -- Kevin Rodrigues
    209297, -- Fred Rodrigues
    209331, -- Mohamed Salah
    209449, -- Gerso Fernandes
    209499, -- Fabinho
    209532, -- Daniel Bachmann
    209620, -- Abdul Rahman Baba
    209658, -- Leon Goretzka
    209660, -- Stefano Magnasco
    209669, -- Dimitri Siovas
    209675, -- Janoi Donacien
    209744, -- Eugenio Mena
    209761, -- Daniel Steres
    209818, -- Joshua Brenet
    209840, -- Julian Jeanvier
    209846, -- Christian Gunter
    209852, -- Brendan Galloway
    209889, -- Raphael Guerriero
    209960, -- Fernando Pacheco
    209981, -- Yassine Bounou
    209989, -- Thomas Partey
    209997, -- Kevin Wimmer
    210007, -- Andre Ramalho Silva
    210008, -- Adrien Rabiot
    210035, -- Grimaldo Garcia
    210047, -- Fabian Schar
    210126, -- Kiyotake
    210214, -- Jozabed Sanchez Ruiz
    210243, -- Ricardo Pereira
    210257, -- Ederson Santana
    210324, -- Jonas Hofmann
    210372, -- Rachid Ghezzal
    210374, -- Juan Pablo Vigon
    210389, -- Brad Smith
    210411, -- Silva Otavio
    210413, -- Alessio Romagnoli
    210423, -- Albert Rusnak
    210438, -- Farid Boulaya
    210455, -- Jonathan Castro
    210514, -- Joao Cancelo
    210603, -- Yasser Al Shahrani
    210617, -- Samuel Castillejo
    210635, -- Kortney Hause
    210648, -- Ahmed Hegazi
    210653, -- Luis Quintana
    210665, -- Marcel Halstenberg
    210679, -- Paulo Oliveira
    210719, -- Marc Oliver Kempf
    210723, -- Niko Giesselmann
    210724, -- Callum Paterson
    210736, -- Emerson Palmieri
    210761, -- Rodolfo Pizarro
    210828, -- Bjorn Engels
    210881, -- John Mc Ginn
    210896, -- Morgan Sanson
    210897, -- Chancel Mbemba
    210930, -- Carles Gil
    210935, -- Domenico Berardi
    210950, -- Pablo De Blasis
    210972, -- Javier Gaitan Manquillo
    210985, -- Ben Osborn
    211060, -- Elson Ferreira De Souza
    211101, -- Ruben Blanco
    211110, -- Paulo Dybala
    211117, -- Dele Alli
    211119, -- Pedro Santos
    211147, -- Valentino Lazaro
    211234, -- Enzo Fernandez
    211241, -- Ruben Pena
    211256, -- Nicolas Tagliafico
    211269, -- Guillermo Fernandez
    211300, -- Anthony Martial
    211320, -- Daniele Rugani
    211368, -- Armindo Bangna
    211381, -- Sofiane Boufal
    211382, -- Ibrahim Amadou
    211385, -- Riza Durmisi
    211513, -- Tom Lawrence
    211514, -- Reece James
    211522, -- Alexander Callens
    211527, -- Alex Gallar
    211575, -- Andre Gomes
    211591, -- Moussa Dembele
    211688, -- Gaya
    211706, -- Pere Pons
    211738, -- Mark Flekken
    211748, -- Kerem Demirbay
    211784, -- Neal Maupay
    211818, -- Kevin Mohwald
    211856, -- Kevin Akpoguma
    211862, -- Andre Hahn
    211872, -- Philip Heise
    211879, -- Janik Haberer
    211899, -- Florian Niederlechner
    211907, -- Jerome Gondorf
    211990, -- Odisseas Vlachodimos
    211999, -- Rani Khedira
    212118, -- Matthew Grimes
    212150, -- Max Meyer
    212151, -- Thomas Strakosha
    212183, -- Nacho Garcia
    212187, -- Philipp Max
    212188, -- Timo Werner
    212190, -- Niklas Sule
    212194, -- Julian Brandt
    212196, -- Pione Sisto
    212198, -- Bruno Fernandes
    212207, -- Nicolae Stanciu
    212212, -- Dominik Kohr
    212214, -- Augusto Solari
    212218, -- Aymeric Laporte
    212228, -- Ivan Toney
    212240, -- Kenan Karaman
    212245, -- Yannick Gerhardt
    212249, -- Sebastian Kerk
    212267, -- Ivan Cavaleiro
    212269, -- Riechedly Bazoer
    212273, -- Clinton N Jie
    212300, -- Jack O Connell
    212404, -- Federico Bernardeschi
    212419, -- Tyrone Mings
    212462, -- Alex Nicolao Telles
    212466, -- Carlos Cisneros
    212476, -- Alvaro Medran
    212478, -- Gyasi Zardes
    212491, -- Arthur Masuaku
    212493, -- Sullay Kaikai
    212501, -- Leander Dendoncker
    212592, -- Andrew Farrell
    212602, -- Diego Llorente
    212607, -- Maxime Chanot
    212622, -- Joshua Kimmich
    212623, -- Santiago Mina
    212626, -- Davie Selke
    212678, -- Ludwig Augustinsson
    212710, -- Joel Castro Pereira
    212715, -- Sebastian Palacios
    212722, -- Deandre Yedlin
    212755, -- Jorrit Hendrix
    212772, -- Oscar Duarte
    212782, -- Hiram Boateng
    212807, -- Kekuta Manneh
    212811, -- Mario Lemina
    212814, -- Joao Mario
    212819, -- Kensuke Nagai
    212831, -- Alisson Becker
    212878, -- Nicolas Castillo
    212883, -- Daniel Amartey
    212888, -- Carlos Salcedo
    212933, -- Laurent Depoitre
    212977, -- Niklas Stark
    213010, -- Miguel Angel Cifuentes
    213017, -- Ben Davies
    213051, -- Mohamed Elneny
    213063, -- Roberto Suarez Pier
    213092, -- Samuel Piette
    213114, -- Diego Rolan
    213134, -- Levin Oztunali
    213135, -- Divock Origi
    213209, -- Kellyn Acosta
    213296, -- Nabil Bentaleb
    213331, -- Jonathan Tah
    213345, -- Kingsley Coman
    213407, -- Matt Macey
    213414, -- Ekong Troost
    213418, -- Chuba Akpom
    213428, -- Clint Irwin
    213439, -- Jonathan Osorio
    213444, -- Ruben Gonzalez
    213490, -- Isaiah Brown
    213536, -- Maxime Crepeau
    213565, -- Thomas Lemar
    213591, -- Juan Cornejo
    213619, -- Sebastian Saez
    213620, -- Felipe Mora
    213642, -- James Wilson
    213648, -- Pierre Hojbjerg
    213655, -- Alex Iwobi
    213661, -- Andreas Christensen
    213665, -- Jordan Houghton
    213666, -- Ruben Loftuscheek
    213686, -- Donald Love
    213692, -- Joshua Harrop
    213694, -- Kenji Gorre
    213696, -- Matthew Willock
    213697, -- Paddy Mcnair
    213699, -- Ashely Fletcher
    213750, -- Ken Sema
    213777, -- Iver Fossum
    213905, -- Sam Gallagher
    213937, -- Ager Aketxe
    213955, -- Sardar Azmoun
    213956, -- Adama Traore
    213991, -- Jefferson Lerma
    214025, -- Cristian Higuita
    214026, -- Johan Mojica
    214047, -- Mateus Uribe
    214096, -- Tim Kleindienst
    214098, -- Rijkaard
    214100, -- Gullit
    214131, -- Jose Ramiro Sanchez
    214136, -- Francisco Meza
    214153, -- Juan Perez
    214267, -- Lineker
    214332, -- Daniel Torres
    214354, -- Dairon Asprilla
    214378, -- David Silva
    214404, -- Valber Huerta
    214491, -- Luis Quinones
    214622, -- Jeremy Toljan
    214639, -- Sergio Postigo
    214649, -- Davor Suker
    214659, -- Nicolas Freire
    214718, -- Martin Rodriguez
    214727, -- Angel Zaldivar
    214770, -- Diego Gonzales
    214781, -- Silvio Romero
    214944, -- Gerard Gumbau
    214947, -- Jean Philippe Gbamin
    214971, -- Francesco Pizzini
    214997, -- Angel Correa
    215061, -- Dario Benedetto
    215079, -- Pablo Perez
    215083, -- Maxi Urruti
    215107, -- Hector Villalba
    215135, -- Leonardo Sigali
    215162, -- Alejandro Donatti
    215178, -- Erik Godoy
    215211, -- Baily Cargill
    215213, -- Axel Werner
    215270, -- Lucas Zelarayan
    215316, -- Geronimo Rulli
    215330, -- Joaquin Correa
    215333, -- Duvan Zapata
    215334, -- Guido Carrillo
    215353, -- Lucas Alario
    215399, -- Ruben Vezo
    215417, -- Christian Mathenia
    215441, -- Sehrou Guirassy
    215556, -- Edimilson Fernandes
    215565, -- Matt Miazga
    215568, -- Jose Manuel Naranjo
    215590, -- Ayoze Perez
    215616, -- Jason Remeseiro
    215639, -- Robert Kenedy Nunes Do Nascimento
    215698, -- Mike Maignan
    215716, -- Aleksandar Mitrovic
    215756, -- Sam Mcqueen
    215758, -- Jason Mccarthy
    215785, -- Keita Balde Diao
    215798, -- Maxwel Cornet
    215818, -- Emerson Hyndman
    215871, -- Alireza Jahanbakhsh
    215914, -- Ngolo Kante
    215930, -- Tin Jedvaj
    216003, -- Bartosz Kapustka
    216054, -- Nery Dominguez
    216150, -- Davide Zappacosta
    216189, -- Ander Capa
    216194, -- Daniel Garcia
    216201, -- Inaki Williams
    216247, -- Marcel Tisserand
    216258, -- Ihlas Bebou
    216266, -- Kenny Tete
    216267, -- Andrew Robertson
    216268, -- Duncan Watmore
    216282, -- Raphael Framberger
    216325, -- Angus Gunn
    216346, -- Alvas Powell
    216352, -- Marcelo Brozovic
    216354, -- Andrej Kramaric
    216381, -- Jean Zimmer
    216388, -- Allan Saint Maximin
    216393, -- Youri Tielemans
    216433, -- Anwar El Ghazi
    216435, -- Stanislav Lobotka
    216447, -- Alvaro Garcia
    216451, -- Jean Michael Seri
    216460, -- Jose Maria Gimenez
    216466, -- Wendell Nascimento Borges
    216467, -- Jack Payne
    216468, -- Juanpi Anor
    216475, -- Jose Luis Morales
    216483, -- Tariqe Fosu
    216497, -- Maximilian Philipp
    216547, -- Rafa Fernandes
    216549, -- Alexander Sorloth
    216594, -- Nabil Fekir
    216605, -- Carlos Akapo
    216643, -- Leo Dubois
    216699, -- Gedion Zelalem
    216749, -- Carlos Mane
    216774, -- Wesley Hoedt
    216778, -- Ruben Semedo
    216791, -- Matthew Pennington
    216939, -- Andre Blake
    217036, -- Alex Moreno
    217606, -- Emmanuel Boateng
    217647, -- Junya Tanaka
    217648, -- Genki Haraguchi
    217699, -- Islam Slimani
    217710, -- Martin Barragan
    217714, -- Paul Arriola
    217845, -- Andrew Hjulsager
    218208, -- Cesar Fuentes
    218339, -- Mahmoud Dahoud
    218341, -- Josip Elez
    218359, -- Didier Ndong
    218464, -- Eliser Quinones
    218659, -- Matt Targett
    218667, -- Bernardo Silva
    218731, -- Alex Rambal
    218746, -- Jose Angel Pozo
    219391, -- Gonzalo Escalante
    219411, -- Jose Izquierdo
    219510, -- Ebenezer Ofori
    219536, -- Ignacio Pussetto
    219571, -- Victor Camarasa
    219652, -- Robert Ibanez
    219680, -- Cedric Hountondji
    219681, -- Jordan Amavi
    219683, -- Corentin Tolisso
    219709, -- Saul Garcia Cabrero
    219732, -- Georges Kevin Nkoudou
    219754, -- Bruno Varela
    219777, -- Jose Manuel Rodriguez
    219795, -- Joel Coleman
    219797, -- Roger Martinez
    219806, -- Fanendo Adi
    219808, -- Pedro Tanausu
    219809, -- Tiemoue Bakayoko
    219841, -- Nicolasjorge Figal
    219914, -- Guillermo Varela
    219932, -- Antonio Sanabria
    219953, -- Adrian Embarba
    220018, -- Ante Rebic
    220029, -- Saif Eddine Khaoui
    220031, -- Oliver Mcburnie
    220085, -- Gian Luca Waldschmidt
    220093, -- Hans Hateboer
    220132, -- Joseba Zaldua
    220165, -- Joel Pohjanpalo
    220182, -- Jason Denayer
    220185, -- Brandon Barker
    220196, -- David Brooks
    220197, -- Kean Bryan
    220209, -- Kemar Lawrence
    220253, -- Munir El Haddadi
    220295, -- Enner Valencia
    220355, -- Alexander Alegria
    220395, -- Alejandro Mula
    220407, -- Martin Dubravka
    220414, -- Diego Rico
    220440, -- Clement Lenglet
    220467, -- Roy Hodgson
    220493, -- Antonio Barreca
    220523, -- Yerry Mina
    220570, -- Jan Bednarek
    220604, -- Jaume Domenech
    220620, -- Florent Hadergjonaj
    220633, -- Demarai Gray
    220637, -- Moi Delgado
    220651, -- Jose Angel Tasende
    220685, -- Leo Bonatini
    220697, -- James Maddison
    220702, -- Gaston Silva
    220708, -- Brandon Borrello
    220710, -- Harry Wilson
    220714, -- Philip Billing
    220746, -- Andrija Zivkovic
    220763, -- Ryan Thomas
    220793, -- Davinson Sanchez
    220814, -- Lucas Hernandez
    220834, -- Marco Asensio
    220854, -- Erick Gutierrez
    220862, -- Jordan Hugill
    220893, -- Courtney Baker Richardson
    220894, -- George Thomas
    220901, -- David Rayamartin
    220925, -- Alessandro Schopf
    220932, -- Lovre Kalinic
    220945, -- Miguel Herrera
    220971, -- Naby Keita
    221087, -- Paul Lopez
    221201, -- Tim Leibold
    221269, -- Jairo Riedewald
    221282, -- Jack Stacey
    221306, -- Michael Barrios
    221342, -- Pablo Maffeo
    221350, -- Thierry Ambrose
    221354, -- Milos Veljkovic
    221358, -- Jordan Rossiter
    221363, -- Donny Van De Beek
    221445, -- Wu Lei
    221452, -- Alexander Mesa
    221479, -- Dominic Calvert Lewin
    221491, -- Nico Elvedi
    221564, -- Matias Nahuel
    221587, -- Joe Lolley
    221618, -- Lys Mousset
    221621, -- Steve Birnbaum
    221634, -- Luciano Acosta
    221660, -- Victor Lindelof
    221680, -- Nick Hagglund
    221696, -- Thomas Mc Namara
    221713, -- Daniel Lovitz
    221743, -- Helder Costa
    221753, -- Marcel Sobottka
    221797, -- Erik Thommy
    221841, -- Adam Armstrong
    221890, -- Jay Fulton
    221923, -- Carlos Vigaray
    221982, -- Patrick Roberts
    221992, -- Hirving Lozano
    222000, -- Michael Laudrup
    222028, -- Julian Weigl
    222077, -- Manuel Locatelli
    222079, -- Josh Onomah
    222096, -- Harry Lewis
    222104, -- Tosin Adarabioyo
    222109, -- Chris Cadden
    222123, -- Aaron Long
    222148, -- Ondrej Duda
    222319, -- Jeison Angulo
    222331, -- Lukas Klostermann
    222352, -- Albian Ajeti
    222357, -- Breel Embolo
    222358, -- Oscar Barreto
    222400, -- Harry Winks
    222404, -- Mathias Normann
    222422, -- Alex Jakubiak
    222467, -- Ivan Lopez
    222481, -- Laurent Blanc
    222492, -- Leroy Sane
    222493, -- Marvin Friedrich
    222509, -- Daniel Ceballos
    222513, -- Rolando Aarons
    222514, -- Freddie Woodman
    222528, -- Lynden Gooch
    222558, -- Rick Karsdorp
    222572, -- Ivan Villar
    222587, -- Franco Escobar
    222634, -- Isaac Success
    222645, -- Leonel Lopez
    222665, -- Martin Odegaard
    222692, -- Benno Schmitz
    222825, -- Chadrac Akolo
    222836, -- Ryan Ledson
    222844, -- Walace Souzasilva
    222864, -- Jack Rose
    222943, -- Jonathan Rodriguez
    222986, -- Masato Morishige
    222991, -- Manabu Saito
    222994, -- Marvelous Nakamba
    223033, -- Jorge Mere
    223061, -- Franco Cervi
    223082, -- Will Norris
    223113, -- Krzysztof Piatek
    223143, -- Ulisses Garcia
    223197, -- Enes Unal
    223198, -- Ali Adnan
    223243, -- Victor Emanuel Aguilera
    223306, -- Jaroslaw Jach
    223334, -- Joelinton Apolinario
    223603, -- Fabian Bredlow
    223608, -- Javier Eraso
    223641, -- Timo Baumgartl
    223671, -- Stefan Posch
    223682, -- Alex Granell
    223697, -- Robin Gosens
    223747, -- Stephen Kingsley
    223816, -- Jonathan Rodriguez
    223848, -- Sergej Milinkovic Savic
    223874, -- Valentin Rongier
    223885, -- Alexander Nubel
    223909, -- Alex Palmer
    223952, -- David Soria
    223959, -- Lucas Torreira
    223963, -- Cameron Humphreys
    224010, -- Jose Aurelio
    224013, -- Sergi Canostenes
    224021, -- Sheyi Ojo
    224030, -- Maxime Lopez
    224065, -- Domingo Blanco
    224069, -- Karl Ekambi Toko
    224081, -- Kalvin Phillips
    224151, -- Henry Martin
    224179, -- Borja Iglesias
    224213, -- Tyronne Ebuehi
    224221, -- Joachim Andersen
    224232, -- Nicolo Barella
    224251, -- Robin Zentner
    224258, -- Kristoffer Ajer
    224263, -- Jonjoe Kenny
    224265, -- Joe Williams
    224293, -- Ruben Neves
    224294, -- Lewis Cook
    224309, -- Joan Jordan
    224367, -- German Lanaro
    224371, -- Jarrod Bowen
    224411, -- Goncalo Guedes
    224425, -- Marius Wolf
    224438, -- Adam Buksa
    224440, -- Julian Pollersbeck
    224458, -- Diogo Jota
    224494, -- Rico Henry
    224520, -- Ryan Kent
    224540, -- Emmanuel Boateng
    224656, -- Ola Aina
    224855, -- George Byers
    224869, -- Unai Bustinza
    224883, -- Steve Mounie
    224887, -- Dom Telford
    224921, -- Adrian Marin
    224947, -- Daniel Grimshaw
    225018, -- Florin Andone
    225024, -- Mason Holgate
    225028, -- Nemanja Radoja
    225100, -- Joe Gomez
    225147, -- Connor Roberts
    225161, -- Jesus Vallejo
    225193, -- Mikel Merino Zazon
    225252, -- Jhon Duque
    225263, -- Duje Caleta Car
    225299, -- Emiliano Velazquez
    225309, -- Nadiem Amiri
    225356, -- Andres Ibarguen
    225375, -- Konrad Laimer
    225383, -- Harry Charsley
    225410, -- Adam Masina
    225423, -- Stiven Vega
    225441, -- Kasey Palmer
    225508, -- Eric Bailly
    225523, -- Inigo Lekue
    225539, -- Dominic Solanke
    225541, -- Aboubakar Kamara
    225543, -- Bradley Collins
    225557, -- Regan Poole
    225591, -- Leonardo Suarez
    225632, -- Oliver Burke
    225647, -- Martin Campana
    225652, -- George Puscas
    225659, -- Guido Rodriguez
    225668, -- Karlan Grant
    225699, -- Anuar Mohamed
    225711, -- Abdou Diallo
    225713, -- Jean Kevin Augustin
    225719, -- Kelechi Iheanacho
    225748, -- Todd Cantwell
    225782, -- Ainsley Maitland Niles
    225793, -- Ben Godfrey
    225844, -- Daniele Verde
    225850, -- Presnel Kimpembe
    225863, -- Olivier Boscagli
    225878, -- Cecilio Dominguez
    225908, -- Reece Oxford
    225953, -- Steven Bergwijn
    226035, -- Jordan Morris
    226078, -- Trezeguet Hassan
    226093, -- Che Adams
    226103, -- Sergio Akieme
    226110, -- Nicolas Pepe
    226116, -- Ryan Sweeney
    226129, -- Jon Gorenc Stankovic
    226161, -- Marcos Llorente
    226162, -- Emiliano Buendia
    226166, -- Nordi Mukiele
    226168, -- Maximilian Eggestein
    226177, -- Sauerbrunn Becky
    226215, -- Sabin Merino
    226221, -- Aritz Elustondo
    226226, -- Giovani Lo Celso
    226229, -- Thilo Kehrer
    226265, -- Carlos Lobos
    226271, -- Fabian Ruiz
    226273, -- Sean Davis
    226301, -- Alex Morgan
    226302, -- Alexandra Popp
    226303, -- Almuth Schult
    226308, -- Dzsenifer Marozsan
    226318, -- Kelley Ohara
    226320, -- Morgan Brian
    226324, -- Carli Lloyd
    226325, -- Ali Krieger
    226327, -- Christen Press
    226328, -- Megan Rapinoe
    226330, -- Tobin Heath
    226331, -- Ashlyn Harris
    226333, -- Julie Johnston
    226335, -- Alyssa Naeher
    226336, -- Crystal Dunn
    226354, -- Melanie Leupolz
    226358, -- Stephanie Houghton
    226359, -- Christine Sinclair
    226376, -- Alejandro Romero Gamarra
    226377, -- Gonzalo Martinez
    226380, -- Hwang Hee Chan
    226401, -- Kieran Dowell
    226456, -- Pablo Fornals
    226491, -- Kieran Tierney
    226495, -- Sergio Santos
    226501, -- Jose Carlos Robles
    226537, -- Vincent Janssen
    226568, -- Ianis Hagi
    226637, -- Ruben Duarte
    226646, -- Felipe Banguero
    226677, -- Juninho Bacuna
    226706, -- Felipe Pires
    226753, -- Andre Onana
    226764, -- George Best
    226766, -- Daniel Podence
    226775, -- Jay Chapman
    226777, -- Cyle Larin
    226781, -- Khiry Shelton
    226786, -- Alex Bono
    226790, -- Wilfred Ndidi
    226797, -- Victor Malcorra
    226798, -- Mauricio Martinez
    226800, -- Benny Ashleyseal
    226803, -- Tim Parker
    226807, -- Christian Roldan
    226851, -- Benjamin Pavard
    226911, -- Liu Shanshan
    226912, -- Yang Li
    226913, -- Zhang Rui
    226915, -- Li Ying
    226917, -- Wang Shanshan
    226922, -- Wu Haiyan
    226923, -- Han Peng
    226927, -- Li Jiayue
    226929, -- Gu Yasha
    226968, -- Nilla Fischer
    226973, -- Sofia Jakobsson
    226975, -- Caroline Seger
    226978, -- Hedvig Lindahl
    226985, -- Olivia Schough
    226987, -- Kosovare Asllani
    226988, -- Elin Rubensson
    226991, -- Linda Sembrant
    227101, -- Emilie Haavi
    227102, -- Caroline Graham Hansen
    227106, -- Diego Gonzalez
    227109, -- Alanna Kennedy
    227111, -- Claire Polkinghorne
    227112, -- Ellise Kellond Knight
    227113, -- Emily Van Egmond
    227115, -- Katrina Gorry
    227116, -- Kyah Simon
    227117, -- Lisa De Vanna
    227118, -- Lydia Williams
    227119, -- Stephanie Catley
    227122, -- Laura Alleway
    227125, -- Samantha Kerr
    227174, -- Matty Cash
    227190, -- Irene Paredes
    227192, -- Jennifer Hermoso
    227193, -- Marta Corredera
    227195, -- Virginia Torrecilla
    227201, -- Vicky Losada
    227203, -- Alexia Putellas
    227222, -- Frederic Guildbert
    227234, -- Lucas Tousart
    227236, -- Andre Zambo
    227241, -- Karen Bardsley
    227246, -- Lucy Bronze
    227254, -- Alex Greenwood
    227257, -- Jordan Nobbs
    227262, -- Jill Scott
    227264, -- Demi Stokes
    227270, -- Ellen White
    227274, -- David Barbona
    227281, -- Kristine Minde
    227282, -- Maren Mjelde
    227286, -- Elise Thorsnes
    227290, -- Marko Dmitrovic
    227300, -- Leonie Maier
    227313, -- Sarah Bouhaddi
    227316, -- Wendie Renard
    227318, -- Amandine Henry
    227326, -- Gaetane Thiney
    227327, -- Sara Dabritz
    227331, -- Eugenie Le Sommer
    227346, -- Griedge Mbock
    227350, -- Marji Amel
    227353, -- Kenza Dali
    227368, -- Cecilie Fiskerstrand
    227383, -- Kadeisha Buchanan
    227384, -- Allysha Chapman
    227387, -- Jessie Fleming
    227394, -- Carlos Gonzalez
    227397, -- Adriana Leon
    227400, -- Erin Mcleod
    227405, -- Sophie Schmidt
    227410, -- Desiree Scott
    227443, -- Yojiro Takahagi
    227447, -- Cecilia Santiago
    227452, -- Stephany Mayor
    227454, -- Carolina Jaramillo
    227458, -- Bianca Sierra
    227503, -- Jacob Bruun Larsen
    227508, -- Gonzalo Melero
    227536, -- Moussa Marega
    227557, -- Mateo Cassierra
    227647, -- Maxi Mittelstadt
    227667, -- Isaac Mbenza
    227678, -- Ezri Konsa
    227732, -- Anastasios Donis
    227796, -- Christian Pulisic
    227813, -- Oleksandr Zinchenko
    227854, -- Matty Foulds
    227927, -- Kyle Walker Peters
    227928, -- Nelson Semedo
    227950, -- Yeray Alvarez
    228017, -- Yuning Zhang
    228080, -- Felix Passlack
    228082, -- Dzenis Burnic
    228151, -- Josh Cullen
    228174, -- Cameron Carter Vickers
    228251, -- Lorenzo Pellegrini
    228295, -- Rob Holding
    228302, -- Alfonso Pedraza
    228332, -- Hamza Choudhury
    228336, -- Florian Grillitsch
    228368, -- Jamie Sterry
    228382, -- Dan Agyei
    228383, -- Kamil Grabara
    228414, -- Matheus Pereira
    228509, -- Jeff Reineadelaide
    228520, -- Ezequiel Avila
    228579, -- Benjamin Henrichs
    228614, -- Gerrit Holtmann
    228618, -- Ferland Mendy
    228635, -- Borja Mayoral
    228681, -- Francisco Sierralta
    228682, -- Raimundo Rebolledo
    228687, -- Kasper Dolberg
    228702, -- Frenkie Dejong
    228717, -- Yoshinori Muto
    228729, -- Bruno Valdez
    228768, -- Xande Silva
    228789, -- Robert Lynchsanchez
    228813, -- Aleix Garcia Serrano
    228815, -- Tyler Roberts
    228838, -- Eric Remedi
    228941, -- Andre Silva
    229037, -- Borja Valle
    229038, -- Christian Rivera
    229050, -- Oskar Buur Rasmussen
    229091, -- Bailey Peacock Farrell
    229163, -- Callum Slattery
    229167, -- Milot Rashica
    229221, -- William De Asevedo Furtado
    229261, -- Denis Zakaria
    229266, -- Joe Rodon
    229348, -- Antonee Robinson
    229359, -- Jorge Miramon
    229379, -- Luca Delatorre
    229476, -- Waldemar Anton
    229477, -- Mike Steven Bahre
    229487, -- Lukas Klunter
    229517, -- Toni Villa
    229558, -- Dayot Upamecano
    229582, -- Gianluca Mancini
    229594, -- Ante Coric
    229636, -- Gaston Pereiro
    229654, -- Gerard Valentin
    229668, -- Mario Hermoso
    229682, -- Dael Fry
    229699, -- Nicolas Benedetti
    229701, -- Philipp Ochs
    229745, -- Bright Enobakhare
    229749, -- Alexander Barboza
    229764, -- Inigo Cordoba
    229788, -- Ruben Alcaraz
    229804, -- Alexandru Mitrita
    229857, -- Stefano Sensi
    229862, -- Edu Exposito
    229880, -- Aaron Wan Bissaka
    229881, -- Ariel Lassiter
    229906, -- Leon Bailey
    229984, -- Ben Chilwell
    230005, -- Tom Davies
    230020, -- Melou Lees
    230065, -- Suat Serdar
    230084, -- Lukas Nmecha
    230142, -- Mikel Oyarzabal
    230564, -- Mijat Gacinovic
    230613, -- Amadou Diawara
    230621, -- Gianluigi Donnarumma
    230658, -- Arthur Melo
    230666, -- Gabriel Jesus
    230767, -- Renato Sanchez
    230794, -- Nacho Gil
    230829, -- Alan Mozo
    230847, -- Zachary Elbouzedi
    230872, -- Mile Svilar
    230876, -- Matt Butcher
    230882, -- Jack Simpson
    230888, -- Aiden O Neill
    230899, -- Ademola Lookman
    230918, -- Trevoh Chalobah
    230938, -- Franck Kessie
    230942, -- Josh Pask
    230977, -- Miguel Almiron
    231110, -- Patrick Erras
    231111, -- Alexander Hack
    231240, -- Emre Mor
    231280, -- Ivan Peralta
    231281, -- Trent Alexander Arnold
    231292, -- Jamal Lewis
    231352, -- Tammy Abraham
    231366, -- Philipp Lienhart
    231406, -- Kyle Edwards
    231408, -- Jonathan Leko
    231410, -- Brahim Diaz
    231416, -- Dodi Lukebakio
    231432, -- Lindsey Horan
    231436, -- Grady Diangana
    231442, -- Marcus Browne
    231443, -- Ousmane Dembele
    231445, -- Josh Dasilva
    231448, -- Reiss Nelson
    231478, -- Lautaro Martinez
    231485, -- Axel Tuanzebe
    231503, -- Bassala Sambou
    231507, -- Alexis Soto
    231535, -- Cameron Borthwick Jackson
    231554, -- James Justin
    231587, -- Luis Caicedo
    231600, -- Marc Navarro
    231633, -- Issa Diop
    231638, -- Adalberto Penaranda
    231677, -- Marcus Rashford
    231743, -- Keinan Davis
    231747, -- Kylian Mbappe
    231823, -- Justin Hoogma
    231866, -- Rodrigo Hernandez
    231873, -- Joni Montiel
    231874, -- Jannes Horn
    231885, -- Kosuke Ota
    231943, -- Richarlison Andrade
    231949, -- Saman Ghoddos
    231979, -- Tsubasa Endoh
    232008, -- Antonio Latorre
    232073, -- Mallory Pugh
    232080, -- Jack Harrison
    232081, -- Richie Laryea
    232097, -- Amine Harit
    232099, -- Marko Grujic
    232104, -- Daniel James
    232119, -- Caglar Soyuncu
    232132, -- Joaquin Moreno
    232148, -- Daniel Salloi
    232207, -- Ivan Saponjic
    232223, -- Konstantinos Tsimikas
    232230, -- Ronald Matarrita
    232244, -- Santiago Ascacibar
    232250, -- Luke Amos
    232270, -- Timothy Fosu Mensah
    232278, -- Santiago Mosquera
    232284, -- Mark Travers
    232297, -- Eddie Howe
    232301, -- Claudio Ranieri
    232302, -- Jurgen Klopp
    232304, -- Mark Hughes
    232305, -- Sam Allardyce
    232307, -- Quique Sanchez Flores
    232363, -- Milan Skriniar
    232381, -- Wesley Ferreira Da Silva
    232425, -- Jose Mourinho
    232432, -- Luka Jovic
    232437, -- Federico Ricca
    232441, -- Masaaki Higashiguchi
    232545, -- Nathan Broadhead
    232581, -- Carlos Eduardo Bendini Giusti
    232597, -- Hiroki Fujiharu
    232608, -- Hiroyuki Abe
    232620, -- Kotaro Omori
    232622, -- Shun Nagasawa
    232626, -- Jae Suk Oh
    232639, -- Ritsu Doan
    232656, -- Theo Hernandez
    232708, -- Milton Valenzuela
    232730, -- Daichi Kamada
    232757, -- Kyle Scott
    232759, -- Josh Tymon
    232790, -- Hiroki Iikura
    232805, -- Bernardo Fernandes
    232811, -- Jun Amano
    232848, -- Yuichi Maruyama
    232860, -- Keigo Higashi
    232862, -- Shoya Nakajima
    232869, -- Gen Shoji
    232870, -- Naomichi Ueda
    232875, -- Daigo Nishi
    232884, -- Shoma Doi
    232909, -- Shunki Takahashi
    232919, -- Naoyuki Fujita
    232926, -- Kazuma Watanabe
    232928, -- Yoshiki Matsushita
    232999, -- Tyler Adams
    233045, -- Ike Ugbo
    233047, -- Joel Latibeaudiere
    233048, -- Tom Dele Bashiru
    233049, -- Jadon Sancho
    233050, -- Matthew Smith
    233051, -- Luke Bolton
    233052, -- Jacob Maddox
    233064, -- Mason Mount
    233096, -- Denzel Dumfries
    233097, -- Rick Van Drongelen
    233138, -- Yu Kobayashi
    233146, -- Shintaro Kurumaya
    233147, -- Ryota Oshima
    233164, -- Arijanet Muric
    233201, -- Chris Mepham
    233207, -- Sei Muroya
    233225, -- Shogo Taniguchi
    233231, -- Jon Bautista
    233250, -- Yuma Suzuki
    233260, -- Alexis Vega
    233267, -- Matt Turner
    233306, -- Dean Henderson
    233314, -- Russell Canouse
    233400, -- Jakob Glesnes
    233419, -- Raphael Diasbelloli
    233472, -- Noah Joel Sarenren Bazee
    233493, -- Jorge Sanchez
    233510, -- Tahith Chong
    233512, -- Alin Tosca
    233606, -- Jesus Angulo
    233705, -- Jacob Sorensen
    233728, -- Mamadou Doucoure
    233731, -- Alexander Isak
    233738, -- Igor Zubeldia
    233746, -- Vivianne Miedema
    233747, -- Sherida Spitse
    233748, -- Lieke Martens
    233749, -- Sari Van Veenendaal
    233751, -- Danielle Van De Donk
    233752, -- Shanice Van De Sanden
    233755, -- Stefanie Van Der Gragt
    233763, -- Pontus Dahlberg
    233782, -- Morgan Feeney
    233785, -- Robin Bormuth
    233837, -- Lina Magull
    233859, -- Rafael Benitez
    233927, -- Lucas Paqueta
    233934, -- Aaron Ramsdale
    233957, -- Sam Field
    233960, -- Lukas Muhl
    234033, -- Borja Lasso
    234035, -- Alvaro Odriozola
    234060, -- Yangel Herrera
    234078, -- Orel Mangala
    234102, -- Ionut Radu
    234122, -- Jose Artur
    234153, -- Carlos Soler
    234171, -- Roland Sallai
    234221, -- Breinner Paz
    234236, -- Patrik Schick
    234249, -- Sam Surridge
    234378, -- Declan Rice
    234396, -- Alphonso Davies
    234399, -- Johannes Eggestein
    234457, -- Oghenekaro Etebo
    234529, -- Walter Mazzarri
    234530, -- Steve Bruce
    234569, -- Florentino Morris
    234570, -- Joao Filipe
    234571, -- Mesaque Dju
    234574, -- Diogo Dalot
    234575, -- Diogo Leite
    234577, -- Diogo Costa
    234579, -- Julian Quinones
    234612, -- Jonathan Ikone
    234640, -- Bakery Jatta
    234642, -- Edouard Mendy
    234679, -- Philippe Sandler
    234706, -- Brandon Mason
    234711, -- Josip Brekalo
    234728, -- Laszlo Benes
    234742, -- Harvey Barnes
    234777, -- Zack Steffen
    234824, -- Yoane Wissa
    234833, -- Florian Muller
    234867, -- Daniel Arzani
    234875, -- Lucas Holer
    234906, -- Aouar Houssem
    234943, -- Florian Neuhaus
    234986, -- Panagiotis Retsos
    235073, -- Gregor Kobel
    235123, -- Andres Iniestra
    235134, -- Pablo Rosario
    235156, -- Jimmy Dunne
    235167, -- Vitaly Janelt
    235172, -- Ruben Vinagre
    235212, -- Achraf Hakimi
    235243, -- Matthijs De Ligt
    235253, -- Patrick Kammerbauer
    235266, -- Christian Fruchtl
    235288, -- Sam Schreck
    235353, -- Ismaila Sarr
    235405, -- Dara Oshea
    235407, -- Salih Ozcan
    235410, -- Youssef Ennesyri
    235450, -- Domingos Quina
    235526, -- Dennis Geiger
    235536, -- Francisco Venegas
    235569, -- Tanguy Ndombele
    235618, -- Kane Wilson
    235619, -- Marcus Edwards
    235647, -- Hans Nunoo Sarpei
    235659, -- Nikita Parris
    235717, -- Berkay Ozcan
    235732, -- David Moyes
    235735, -- Ethan Ampadu
    235781, -- Santiago Comesana
    235790, -- Kai Havertz
    235794, -- Eze Eberechi
    235805, -- Federico Chiesa
    235813, -- Razvan Marin
    235855, -- Joel Asoro
    235883, -- Ryan Sessegnon
    235889, -- Cengiz Under
    235944, -- Brais Mendez
    235945, -- Marc Roca
    236007, -- Ezequiel Barco
    236009, -- Cameron John
    236015, -- Morgan Gibbswhite
    236043, -- Daniel Batty
    236046, -- Ivan Zlobin
    236221, -- Darko Brasanac
    236239, -- Alfie Whiteman
    236245, -- Alberth Elis
    236246, -- Ovie Ejaria
    236248, -- Ben Woodburn
    236276, -- Arnaut Danjuma Groeneveld
    236295, -- Aaron Martin
    236315, -- Alfie Jones
    236316, -- Yan Valery
    236319, -- Thomas O Connor
    236325, -- Jake Vokins
    236331, -- Erick Cabaco
    236401, -- Noussair Mazraoui
    236441, -- Fabricio Bustos
    236457, -- Dimitris Giannoulis
    236480, -- Yves Bissouma
    236496, -- Matteo Guendouzi
    236498, -- Sam Lammers
    236499, -- Douglas Luiz
    236508, -- Adrian Dieguez
    236515, -- Alvaro Fernandezllorente
    236529, -- Steven Alzate
    236532, -- Robin Koch
    236583, -- Jiri Pavlenka
    236587, -- Marco Farfan
    236600, -- Japhet Tanganga
    236610, -- Moise Kean
    236624, -- Aymen Barkok
    236627, -- Julius Kade
    236649, -- Yanick Van Osch
    236679, -- Oscar Melendo
    236699, -- Sasa Lukic
    236786, -- Martin Terrier
    236792, -- Tomas Soucek
    236875, -- Andreas Poulsen
    236920, -- Justin Kluivert
    236944, -- Fousseni Diabate
    236947, -- Jordan Torunarigha
    236987, -- Boubacar Kamara
    236988, -- Eddie Nketiah
    237000, -- Reggie Cannon
    237024, -- Gian Luca Itter
    237034, -- Juan Hernandez
    237043, -- Roberto Alvarado
    237067, -- Pele
    237075, -- Christian Ramirez
    237139, -- Tashan Oakley Boothe
    237153, -- Latif Blessing
    237160, -- Ro Shaun Williams
    237161, -- Sean Longstaff
    237176, -- Ryan Schofield
    237183, -- Matias Rojas
    237201, -- Kendall Mcintosh
    237221, -- Juan Foyth
    237223, -- Julian Gressel
    237238, -- Scott Mctominay
    237239, -- Enis Bardhi
    237242, -- Andres Felipe Roman
    237252, -- Jake Nerwinski
    237255, -- Miles Robinson
    237256, -- Jeremy Ebobisse
    237286, -- Aaron Connolly
    237328, -- Nathan Tella
    237329, -- Joseph Willock
    237383, -- Alessandro Bastoni
    237388, -- Carlo Ancelotti
    237389, -- Unai Emery
    237407, -- Chris Durkin
    237429, -- Genta Miura
    237469, -- Nouhou Tolo
    237560, -- Moussa Djenepo
    237595, -- Marco Friedl
    237604, -- Alan Franco
    237629, -- Arne Maier
    237677, -- Robbie Mc Court
    237678, -- Ibrahima Konate
    237683, -- Nathan Holland
    237692, -- Phil Foden
    237695, -- Miguel Ortega
    237700, -- Tosin Kehinde
    237702, -- Matt Olosunde
    237704, -- Joao Virginia
    237841, -- Michael Murillo
    237916, -- Will Smallbone
    237985, -- Kevin Danso
    238049, -- Paxton Pomykal
    238059, -- Dan Kemp
    238060, -- Nathan Trott
    238061, -- Alfie Lewis
    238062, -- Beni Baningime
    238067, -- Nicolo Zaniolo
    238068, -- Marco Richter
    238070, -- Jamie Cumming
    238071, -- Dujon Sterling
    238072, -- Eduard Lowen
    238074, -- Reece James
    238114, -- Carlos Vargas
    238126, -- Jon Guridi
    238157, -- Mads Roerslev
    238186, -- Marcin Bulka
    238222, -- Felix Beijmo
    238274, -- Florinel Coman
    238305, -- Nacho Vidal
    238380, -- Lev Yashin
    238399, -- Zinedine Zidane
    238409, -- Marlon Fossey
    238460, -- Rhian Brewster
    238470, -- Sara Doorsoun
    238476, -- Dan Axel Zagadou
    238616, -- Pedro Neto
    238717, -- Ethan Pinnock
    238736, -- Renat Dadashov
    238744, -- Weston Mckennie
    238794, -- Vinicius Junior
    238857, -- Wilson Manafa
    238922, -- Mark Anthony Kaye
    238958, -- Rekeem Harper
    239015, -- Emmanuel Dennis
    239053, -- Federico Valverde
    239085, -- Haaland
    239097, -- Dennis Srbeny
    239195, -- Stanislav Cherchisov
    239207, -- Maximiliano Gomez
    239228, -- Paul Clement
    239322, -- Christoph Zimmermann
    239360, -- Pascal Struijk
    239364, -- Philipp Kohn
    239367, -- Robin Hack
    239368, -- Mitchel Bakker
    239380, -- Noa Lang
    239433, -- Nemanja Maksimovic
    239439, -- Przemyslaw Placheta
    239452, -- Ibrahima Diallo
    239454, -- Brian Figueroa
    239506, -- Sam Hughes
    239571, -- Tim Handwerker
    239676, -- Kyle Taylor
    239681, -- Omar Bertel
    239696, -- Florent Muslija
    239704, -- Kai Wagner
    239744, -- Mickael Cuisance
    239747, -- Sergio Cordova
    239778, -- Jakub Moder
    239782, -- Bryan Acosta
    239800, -- Steven Sessegnon
    239818, -- Ruben Dias
    239822, -- Eduardo Tercero
    239837, -- Alexis Macallister
    239890, -- Ozan Kabak
    239945, -- Fernando Beltran
    239961, -- Juan Esteban Moreno
    239965, -- Jader Valencia
    239970, -- Paulinho Sampaio
    239978, -- Dennis Man
    239981, -- Jann Fiete Arp
    240026, -- Anthony Fontana
    240060, -- Max Aarons
    240130, -- Eder Militao
    240175, -- Bruno Jordao
    240199, -- David Wagner
    240243, -- Matheus Cunha
    240289, -- Fernando Calero
    240311, -- Luca Zidane
    240319, -- Timothy Tillman
    240451, -- Jan Niklas Beste
    240488, -- Chris Hughton
    240507, -- Angel Gomes
    240511, -- Indy Boonen
    240513, -- Ethan Hamilton
    240517, -- Callum Whelan
    240690, -- Nicolas Gonzalez
    240697, -- Shandon Baptiste
    240734, -- Matt Oriley
    240740, -- Callum Hudson Odoi
    240786, -- Ali Koiki
    240833, -- Youssoufa Moukoko
    240863, -- Conor Coventry
    240865, -- Anthony Scully
    240866, -- Reece Hannam
    240867, -- Ajibola Alese
    240900, -- Unai Nunez
    240913, -- Caoimhin Kelleher
    240926, -- Nathaniel Phillips
    240947, -- Mitchell Tyrick
    240950, -- Pedro Goncalves
    240976, -- Marcelo Saracchi
    240981, -- Max Sanders
    240982, -- Junior Moreno
    241005, -- Joaquin Ardaiz
    241036, -- George Marsh
    241042, -- Oliver Skipp
    241050, -- Alexander Meyer
    241084, -- Luis Diaz
    241095, -- Nikola Vlasic
    241096, -- Sandro Tonali
    241150, -- Manuel Mbom
    241184, -- Junior Firpor
    241188, -- Setien Quique
    241240, -- Tatsuya Ito
    241376, -- Michel Gonzalez
    241377, -- Eusebio Sacristan
    241378, -- Jose Luis Mendilibar
    241386, -- Jamie Soule
    241395, -- Pablo Machin
    241435, -- Khanya Leshabela
    241461, -- Ferran Torres
    241464, -- Pau Torres
    241487, -- Jesus Ferreira
    241496, -- Timothy Weah
    241497, -- Colin Dagba
    241523, -- Marcus Forss
    241611, -- Marcelino Garcia Toral
    241612, -- Juan Ramon Muniz
    241643, -- Viktor Johansson
    241651, -- Viktor Gyokeres
    241715, -- Jose Ziganda
    241737, -- Birk Risa
    241743, -- Ulises Segura
    241811, -- Sergio Gomez Martinez
    241842, -- Ben Johnson
    241907, -- Diego Rossi
    241982, -- Elliot Watt
    242000, -- Konstantinos Mavropanos
    242052, -- Jesus Medina
    242069, -- Jordan Sierra
    242075, -- Josh Sargent
    242118, -- Sebastian Cordova
    242236, -- Ferro Reis
    242238, -- Oumar Solet
    242242, -- Sebastien Cibois
    242265, -- Michael Obafemi
    242364, -- Aliou Traore
    242382, -- Luca Ashbyhammond
    242418, -- Tariq Lamptey
    242434, -- Curtis Jones
    242444, -- Joao Felix
    242451, -- Josue Colman
    242479, -- David Henriquez
    242516, -- Cody Gakpo
    242534, -- Christian Casseres Jr
    242554, -- Brandon Bye
    242596, -- Tristan Blackmon
    242628, -- George Bello
    242641, -- Rayan Aitnouri
    242656, -- Illan Meslier
    242732, -- Owen Otasowie
    242752, -- Nathan Ferguson
    242794, -- Imran Louza
    242946, -- Oladapo Afolayan
    242965, -- Fraser Hornby
    242967, -- Callum Morton
    242995, -- Joseph Mora
    242997, -- Linton Maina
    243009, -- Derek Cornelius
    243014, -- Bryan Mbeumo
    243044, -- Nnamdi Ofoborh
    243048, -- Will Dennis
    243055, -- Rafael Camacho
    243057, -- Neco Williams
    243184, -- Javi Gracia
    243208, -- Carlos Carvalhal
    243231, -- Enock Mwepu
    243235, -- Olivier Mbaizo
    243249, -- Jurgen Ekkelenkamp
    243282, -- Dwight Mc Neil
    243353, -- Bali Mumba
    243386, -- Diego Valencia
    243388, -- Borna Sosa
    243390, -- Ian Carl Poveda
    243391, -- Iker Pozo
    243392, -- Rabbi Matondo
    243393, -- Taylor Richards
    243403, -- Claire Emslie
    243404, -- Georgia Stanway
    243414, -- Brandon Williams
    243449, -- Lucas Perrin
    243478, -- Enzo Loiodice
    243573, -- Anthony Racioppi
    243608, -- Ryan Giles
    243630, -- Jonathan David
    243650, -- David Tavares
    243656, -- Nemanja Radonjic
    243675, -- Kjell Scherpen
    243686, -- Chiquinho Machado
    243705, -- Florian Chabrolle
    243710, -- Garissone Innocent
    243712, -- Pep Guardiola
    243767, -- Gavin Kilkenny
    243812, -- Rodrygo Goes
    243828, -- Matthew Longstaff
    243874, -- Julen Lopetegui
    243932, -- David Lennart Phillip
    244068, -- Keven Schlotterbeck
    244191, -- Joseph Anang
    244196, -- Dominic Thompson
    244288, -- Adam Idah
    244363, -- Daniel Fuzato
    244448, -- Juan Sanchezpurata
    244470, -- Vladimir Coufal
    244558, -- Idekel Dominguez
    244621, -- Vinicius Morais
    244680, -- Mathieu Choiniere
    244778, -- Fransisco Trincao
    244809, -- Marcus Dewhurst
    244835, -- Antonio Lopez
    244915, -- Mahammed Salisu
    244919, -- Martin Pascual
    244987, -- Milton Alvarez
    245021, -- Loum Mamadou
    245037, -- Eric Garciamartret
    245061, -- Julian Lopez
    245209, -- Michal Sadilek
    245211, -- Jordan Teze
    245226, -- Goncalo Cardoso
    245236, -- Neil Warnock
    245237, -- Ignacio Saavedra
    245278, -- Tomas Tavares
    245279, -- Sergio Reguilon
    245286, -- Jan Zamburek
    245336, -- Maximilian Kilman
    245367, -- Xavi Simons
    245428, -- Chima Okoroji
    245541, -- Gio Reyna
    245632, -- Miguel Angel Morro
    245715, -- Jamie Shackleton
    245725, -- Diego Rosales
    245733, -- Hendrik Weydandt
    245902, -- Troy Parrott
    245992, -- Billy Gilmour
    246053, -- Joe Gelhardt
    246069, -- Lukas Rupp
    246104, -- Ryan Gravenberch
    246137, -- Kayne Ramsay
    246147, -- Mason Greenwood
    246272, -- Marie Katoto
    246401, -- Fabrice Hartmann
    246402, -- Mads Bidstrup
    246430, -- Dusan Vlahovic
    246646, -- Maxence Caqueret
    246669, -- Bukayo Saka
    246763, -- Ki Jana Hoever
    246861, -- Alessio Riccardi
    246863, -- Felix Nmecha
    246923, -- Jacob Ramsey
    246960, -- Mohamed Ihattaren
    247140, -- Josh Benson
    247393, -- Evelio Cardozo
    247394, -- Dejan Kulusevski
    247512, -- Jordyn Huitema
    247517, -- John Barnes
    247553, -- Garrincha
    247601, -- Rhys Williams
    247622, -- Bernardo Rosa
    247623, -- Jeremy Ngakia
    247699, -- Kenny Dalglish
    247703, -- Ian Rush
    247741, -- Anthony Glennon
    247851, -- Bruno Guimaraes
    248146, -- Ian Wright
    248243, -- Eduardo Camavinga
    248603, -- Loic Mbe Soh
    248604, -- Arthur Zagre
    249063, -- Brendan Rogers
    249078, -- Bruno Lage
    249119, -- Chris Wilder
    249179, -- Daniel Farke
    249224, -- Dean Smith
    250851, -- Frederik Alves
    250890, -- Gianluca Zambrotta
    251098, -- Lisa Zimouche
    251217, -- Jean Lucas
    251341, -- Marley Ake
    251387, -- Luis Diaz
    251484, -- Frank Lampard
    251521, -- Niall Huggins
    251530, -- Nuno Tavares
    251566, -- Gabriel Martinelli
    251573, -- Renan Lodi
    251804, -- Sergino Dest
    252032, -- Mouhamed Mbaye
    252033, -- Tomas Esteves
    252037, -- Fabio Silva
    252038, -- Romario Baro
    252042, -- Joao Pedro
    252238, -- Alan Velasco
    252371, -- Jude Bellingham
    252454, -- Haret Ortega
    252460, -- Juan Jose Miguel
    252466, -- Devid Bouah
    252577, -- Joao Ferreira
    252594, -- Isaac Lihadji
    252935, -- Leonardo Fernandez
    252961, -- Tanguy Kouassi
    253004, -- Ansu Fati
    253100, -- Raymundo Fulgencio
    253102, -- Adil Aouchiche
    253160, -- Anthony Joshua
    253407, -- Sam Greenwood
    253568, -- Leonardo Campana
    253691, -- Aldo Mota
    254113, -- Chem Campbell
    254120, -- Tommy Doyle
    254588, -- Billy Koumetio
    254642, -- Ferenc Puskas
    254796, -- Noni Madueke
    254807, -- Kwadwo Baah
    254891, -- Jose Andres Martinez
    255110, -- Henry Kessler
    255150, -- Niels Nkounkou
    255151, -- Simon Ngapandouetnbu
    255253, -- Vitor Ferreira
    256216, -- Emmanuel Longelo
    256630, -- Florian Wirtz
    256739, -- Diplo
    256913, -- Fred
    256914, -- Winnie Harlow
    256915, -- Patrick Mahomes
    256916, -- Daniel Ricciardo
    256948, -- Christos Tzolis
    257200, -- Giannis Antetokounmpo
    257201, -- Joel Embiid
    257202, -- Lamar Jackson
    257224, -- Gabriel Medina
    257226, -- Natalia Guitler
    257534, -- Cole Palmer
    257615, -- Lewis Hamilton
    257616, -- Djsnake
    258126, -- Dua Lipa
    258127, -- Anitta
    258515, -- Ademipo Odubeko
    258758, -- Theo Corbeanu
    259031, -- Liam Delap
    259356, -- Carney Chukwuemeka
    260801, -- Kiyan Prince
    261025, -- Dane Scarlett
    261336, -- Bidace Philogene
    261581, -- David Beckham
    261593, -- Jurgen Kohler
    261647, -- Andrew Omobamidele
    262271, -- Diego Milito
    263582 -- Harris Peart
}

gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

function has_headasset(pids, pid)
    for i=1, #pids do
        if pid == pids[i] then return true end
    end
    return false
end

local first_record = game_db_manager.tables["players"]["first_record"]
local record_size = game_db_manager.tables["players"]["record_size"]
local written_records = game_db_manager.tables["players"]["written_records"]

local row = 0
local current_addr = first_record
local last_byte = 0
local is_record_valid = true

while true do
    if row >= written_records then
        break
    end
    current_addr = first_record + (record_size*row)
    last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
    is_record_valid = not (bAnd(last_byte, 128) > 0)
    if is_record_valid then
        local playerid = game_db_manager:get_table_record_field_value(current_addr, "players", "playerid")
        if playerid > 0 and has_headasset(valid_headmodels, playerid) then
            game_db_manager:set_table_record_field_value(current_addr, "players", "headassetid", playerid)
            game_db_manager:set_table_record_field_value(current_addr, "players", "hashighqualityhead", 1)
            game_db_manager:set_table_record_field_value(current_addr, "players", "headclasscode", 0)
        else
            game_db_manager:set_table_record_field_value(current_addr, "players", "hashighqualityhead", 0)
            game_db_manager:set_table_record_field_value(current_addr, "players", "headclasscode", 1)
        end
    end
    row = row + 1
end

showMessage("Done")
