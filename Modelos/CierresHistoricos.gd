extends RefCounted
## Textos originales para lectura escolar. Fuentes y alcance en docs/resultados-mision.md.
const DATOS := {
	"francia": {
		"logro": "Evacuación completada con vida",
		"hechos": "En mayo de 1940, la ofensiva alemana empujó a fuerzas aliadas hacia Dunkerque. Entre el 26 de mayo y el 4 de junio, la operación Dynamo evacuó a unos 338.000 soldados británicos, franceses y de otros países aliados hacia Gran Bretaña.",
		"importancia": "Salvar a tantos soldados permitió conservar fuerzas para continuar la guerra. Fue un rescate dentro de una derrota militar: la evacuación no detuvo la conquista de Francia. Resistir también podía significar ganar tiempo para que otros escaparan.",
		"personas": "La retirada dependió de quienes defendieron el perímetro y de tripulaciones militares y civiles. Hubo muertos, prisioneros y personas que no pudieron salir. Una evacuación exitosa no borra esas pérdidas.",
		"idea": "Salvar vidas y conservar fuerzas puede ser un objetivo estratégico, incluso cuando se pierde terreno.",
		"hitos": ["10 MAY 1940 · Comienza la ofensiva alemana en el oeste.", "26 MAY – 4 JUN · Evacuación de Dunkerque.", "JUN 1940 · Francia es derrotada; Gran Bretaña continúa la guerra."],
		"pregunta": "¿Por qué una retirada puede ser importante para seguir resistiendo?",
		"respuesta": "Porque permite salvar personas y reorganizar fuerzas. En Dunkerque se rescató a soldados, aunque la campaña de Francia se perdió.",
		"fuentes": [{"nombre": "English Heritage · Operación Dynamo", "url": "https://www.english-heritage.org.uk/visit/places/dover-castle/history-and-stories/operation-dynamo-things-you-need-to-know/"}, {"nombre": "RAF Museum · La evacuación de Dunkerque", "url": "https://www.rafmuseum.org.uk/blog/the-rafs-role-in-the-evacuation-of-dunkirk/"}],
	},
	"alamein": {
		"logro": "Dos defensas superadas; salida alcanzada",
		"hechos": "Del 23 de octubre al 4 de noviembre de 1942, el Octavo Ejército, al mando de Bernard Montgomery, derrotó a las fuerzas alemanas e italianas en El Alamein, Egipto. Combatieron soldados de muchos países, incluidos territorios del Imperio británico.",
		"importancia": "La victoria hizo retroceder al Eje y redujo la amenaza sobre Egipto y el canal de Suez, una ruta estratégica entre el Mediterráneo y el mar Rojo. Ayudó a cambiar el rumbo de la campaña del norte de África, pero no terminó por sí sola la guerra.",
		"personas": "El avance exigió abrir pasos entre minas y coordinar infantería, artillería y tanques. El agua, el combustible y los suministros eran decisivos. Detrás de cada avance hubo soldados heridos, muertos y prisioneros.",
		"idea": "Una batalla depende de la coordinación, el terreno y los suministros, además de las armas.",
		"hitos": ["JUL 1942 · La primera batalla frena el avance del Eje.", "23 OCT – 4 NOV · La segunda batalla fuerza su retirada.", "MAY 1943 · Termina la campaña del norte de África."],
		"pregunta": "¿Por qué el combustible y el agua podían ser tan importantes como un tanque?",
		"respuesta": "Sin suministros, las unidades no podían moverse ni sostener el combate en el desierto. La victoria necesitaba logística y coordinación.",
		"fuentes": [{"nombre": "National Army Museum · Segunda batalla de El Alamein", "url": "https://www.nam.ac.uk/explore/battle-alamein"}, {"nombre": "National Army Museum · Campaña del norte de África", "url": "https://www.nam.ac.uk/explore/struggle-north-africa-1940-43"}],
	},
	"berlin": {
		"logro": "Objetivo final alcanzado; campaña completada",
		"hechos": "En abril de 1945, el Ejército Rojo avanzó sobre Berlín. Los combates urbanos terminaron el 2 de mayo con la rendición de las fuerzas alemanas en la ciudad. La capital quedó devastada y la población civil sufrió las consecuencias de la batalla.",
		"importancia": "La caída de Berlín acompañó el derrumbe del régimen nazi. Alemania firmó su rendición en Reims el 7 de mayo y en Berlín el 8. La victoria en Europa se conmemora el 8 de mayo, y el 9 en varios países por la diferencia horaria.",
		"personas": "El final de los combates no reparó inmediatamente las pérdidas humanas ni la destrucción. La Segunda Guerra Mundial continuó en Asia y el Pacífico hasta la rendición formal de Japón, el 2 de septiembre de 1945.",
		"idea": "La rendición de Berlín, el final de la guerra en Europa y el final de la guerra mundial son momentos distintos.",
		"hitos": ["2 MAY 1945 · Se rinden las fuerzas alemanas de Berlín.", "8–9 MAY · Se conmemora la victoria en Europa.", "2 SEP · Japón firma su rendición; termina la guerra mundial."],
		"pregunta": "¿Terminó toda la Segunda Guerra Mundial cuando cayó Berlín?",
		"respuesta": "No. Terminó una batalla decisiva en Europa. La guerra continuó en Asia y el Pacífico hasta septiembre de 1945.",
		"fuentes": [{"nombre": "USHMM · Fechas clave de 1945 (español)", "url": "https://encyclopedia.ushmm.org/content/es/article/1945-key-dates"}, {"nombre": "National Archives · Rendición de Alemania", "url": "https://www.archives.gov/milestone-documents/surrender-of-germany"}, {"nombre": "Australian War Memorial · Rendición y conmemoración", "url": "https://www.awm.gov.au/wartime/87/article-five"}],
	},
}

static func obtener(id: String) -> Dictionary:
	return DATOS.get(id, {}).duplicate(true)
