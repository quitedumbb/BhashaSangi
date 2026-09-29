import os
import json
import re
import requests
from dotenv import load_dotenv

load_dotenv()

# Comprehensive and highly accurate JCERT / CBSE Class 3 Curriculum Pedagogical Knowledge Base
JCERT_KNOWLEDGE_BASE = {
    # --- Science / EVS Chapters ---
    "poonam": {
        "summary_en": "Poonam observes diverse animals and birds in our local surroundings. Animals live on land, in water, on trees, and fly in the sky. They move by walking, hopping, crawling, flying, or swimming.",
        "summary_hi": "पूनम अपने आस-पास विभिन्न पशु-पक्षियों का अवलोकन करती है। जीव जमीन पर, पानी में, पेड़ों पर रहते हैं और हवा में उड़ते हैं। वे चलने, फुदकने, रेंगने, उड़ने या तैरने की क्रिया द्वारा गति करते हैं।",
        "key_points": [
            "Animal Habitats: Land (terrestrial), Water (aquatic), Trees (arboreal), and Air (aerial).",
            "Movement: Birds fly with wings; snakes crawl with scales; frogs hop and swim; monkeys climb.",
            "Sounds & Calls: Crows caw, pigeons coo, koels sing melodiously, and frogs croak during rains.",
            "Observation Ethics: Observe nature and wildlife gently without throwing stones or harming nests."
        ],
        "vocabulary": [
            {"word_en": "Habitat", "word_hi": "प्राकृतिक वास / आवास", "meaning": "The natural home or environment of an animal or plant."},
            {"word_en": "Arboreal", "word_hi": "वृक्षवासी", "meaning": "Animals like monkeys and squirrels that spend most time in trees."},
            {"word_en": "Crawl", "word_hi": "रेंगना", "meaning": "Moving close to the ground, typical of lizards, snakes, and snails."},
            {"word_en": "Feathers", "word_hi": "पंख / पर", "meaning": "Light structures providing warmth and lift for birds to fly."}
        ],
        "activity": {
            "title": "Local Animal Observation Chart",
            "instructions": "Take students into the school compound. List 3 animals on the ground, 3 birds on branches, and 2 insects near soil. Imitate their distinct sounds together."
        },
        "questions": [
            {
                "question_en": "Which animals did Poonam see resting on the Banyan tree branches?",
                "question_hi": "पूनम ने बरगद के पेड़ की शाखाओं पर किन जीवों को देखा?",
                "answer_en": "Poonam saw a pigeon, squirrel, crow, monkey, butterflies, and ants on the tree.",
                "answer_hi": "पूनम ने कबूतर, गिलहरी, कौआ, बंदर, तितलियाँ और चींटियों को पेड़ पर देखा।"
            },
            {
                "question_en": "How do animals move from one place to another?",
                "question_hi": "जानवर एक स्थान से दूसरे स्थान तक कैसे गति करते हैं?",
                "answer_en": "Some walk with feet, some fly with wings, some crawl on bellies, and some swim in water.",
                "answer_hi": "कुछ पैरों से चलते हैं, कुछ पंखों से उड़ते हैं, कुछ पेट के बल रेंगते हैं और कुछ पानी में तैरते हैं।"
            }
        ]
    },

    "plant_fairy": {
        "summary_en": "Plants and trees exhibit remarkable diversity in trunks, branches, and leaf shapes, colors, and margins. Leaves have veins that transport water. Sacred and medicinal trees like Sal, Mahua, and Neem sustain our ecosystem.",
        "summary_hi": "पेड़-पौधों के तने, शाखाएं और पत्ते विभिन्न आकार, रंग और किनारों वाले होते हैं। पत्तों में शिराएं होती हैं जो पानी पहुंचाती हैं। साल, महुआ और नीम जैसे औषधीय वृक्ष हमारे पर्यावरण की जीवनरेखा हैं।",
        "key_points": [
            "Leaf Anatomy: Petiole (stalk), blade (lamina), midrib, veins, and margins (smooth or serrated).",
            "Trunk Types: Thick woody trunks (Banyan, Mango) vs. soft slender stems (grasses, herbs).",
            "Medicinal Value: Neem purifies and heals; Tulsi cures colds; Mahua flowers give nourishment.",
            "Eco-Care: Never pluck fresh green leaves unnecessarily; collect dry fallen leaves for compost."
        ],
        "vocabulary": [
            {"word_en": "Chlorophyll", "word_hi": "हरितलवक / पर्णहरित", "meaning": "Green pigment in leaves that traps sunlight to make food."},
            {"word_en": "Leaf Margin", "word_hi": "पत्ते का किनारा", "meaning": "The outer boundary of a leaf which can be smooth, wavy, or toothed."},
            {"word_en": "Sal Tree", "word_hi": "साल / सखुआ", "meaning": "State tree of Jharkhand, strong timber revered during Sarhul festival."},
            {"word_en": "Compost", "word_hi": "जैविक खाद", "meaning": "Natural fertilizer made from decomposing dry leaves and organic matter."}
        ],
        "activity": {
            "title": "Leaf Texture Rubbing & Herbarium",
            "instructions": "Place a fallen leaf under paper with veins facing up. Rub gently with a crayon to reveal delicate vein patterns."
        },
        "questions": [
            {
                "question_en": "Why are leaves called the kitchen or food factory of plants?",
                "question_hi": "पत्तों को पौधों की रसोई या भोजन बनाने की फैक्ट्री क्यों कहा जाता है?",
                "answer_en": "Leaves prepare food for the whole plant using sunlight, air, and water through photosynthesis.",
                "answer_hi": "पत्ते सूर्य के प्रकाश, हवा और पानी की मदद से पूरे पौधे के लिए भोजन बनाते हैं।"
            },
            {
                "question_en": "Name two medicinal trees common in Jharkhand forests and villages.",
                "question_hi": "झारखंड के जंगलों और गांवों में पाए जाने वाले दो औषधीय पेड़ों के नाम बताइए।",
                "answer_en": "Neem (antiseptic leaves) and Sal/Sakhua (bark used in traditional remedies).",
                "answer_hi": "नीम (रोगनिरोधी गुण) और साल/सखुआ (छाल और पत्तों का पारंपरिक उपयोग)।"
            }
        ]
    },

    "water": {
        "summary_en": "Water is the lifeline for all living organisms, crops, and industries. Water changes forms: liquid, solid ice, and water vapor. We must conserve rainwater and drink boiled or filtered safe water.",
        "summary_hi": "जल सभी जीवों, फसलों और प्रकृति के लिए अमूल्य है। पानी तीन अवस्थाओं में मिलता है: तरल पानी, ठोस बर्फ और भाप। हमें वर्षा जल का संचयन करना चाहिए और हमेशा शुद्ध पानी पीना चाहिए।",
        "key_points": [
            "Forms of Water: Ice/Snow (solid), Water (liquid), Steam/Vapor (gas).",
            "Sources of Water: Rain, rivers, natural springs (chua/dari), ponds (bandh), and tube wells.",
            "Water Cycle: Sun heats water -> evaporation -> clouds form -> condensation -> rainfall.",
            "Conservation: Do not leave taps open; build soak pits and village check dams for rainwater harvesting."
        ],
        "vocabulary": [
            {"word_en": "Evaporation", "word_hi": "वाष्पीकरण", "meaning": "Process where liquid water turns into invisible vapor due to heat."},
            {"word_en": "Condensation", "word_hi": "संघनन", "meaning": "When water vapor cools down and turns back into water drops, forming clouds."},
            {"word_en": "Precipitation", "word_hi": "वर्षा / वर्षण", "meaning": "Rain, hail, or snow falling from clouds to the ground."},
            {"word_en": "Conservation", "word_hi": "जल संरक्षण", "meaning": "Protecting, saving, and judiciously managing water resources."}
        ],
        "activity": {
            "title": "Mini Water Cycle in a Sealed Jar",
            "instructions": "Place warm water in a clear glass jar and cover with ice cubes on top. Observe water droplets forming and raining inside the jar."
        },
        "questions": [
            {
                "question_en": "Why should we avoid drinking unboiled water from open ponds?",
                "question_hi": "हमें खुले तालाबों का बिना उबला पानी क्यों नहीं पीना चाहिए?",
                "answer_en": "Open pond water can contain invisible dirt and disease-causing germs that cause cholera and diarrhea.",
                "answer_hi": "खुले तालाब के पानी में सूक्ष्म कीटाणु और गंदगी हो सकती है जिससे हैजा और पेट की बीमारियां होती हैं।"
            },
            {
                "question_en": "Mention two simple ways to save water at school and home.",
                "question_hi": "स्कूल और घर में पानी बचाने के दो आसान उपाय बताइए।",
                "answer_en": "Turn off taps while brushing teeth and collect excess water to irrigate school garden plants.",
                "answer_hi": "ब्रश करते समय नल बंद रखना और बचे हुए पानी से स्कूल की क्यारियों को सींचना।"
            }
        ]
    },

    "our_first_school": {
        "summary_en": "Our family is our first school. Long before entering classroom gates, we learn values, kindness, sharing, language, and everyday habits from parents, grandparents, and siblings.",
        "summary_hi": "हमारा परिवार ही हमारा पहला विद्यालय है। स्कूल जाने से पहले हम बोलना, शिष्टाचार, एक-दूसरे की मदद करना और अच्छी आदतें अपने माता-पिता और बड़ों से सीखते हैं।",
        "key_points": [
            "First Teachers: Mother, father, grandparents, and family elders nurture our earliest learning.",
            "Family Types: Nuclear family (parents and children) and Joint family (grandparents, uncles, aunts, cousins).",
            "Family Traits: Physical resemblance (eyes, smile, height) and voice tones passed across generations.",
            "Respect & Cooperation: Sharing household responsibilities like tidying rooms and watering plants."
        ],
        "vocabulary": [
            {"word_en": "Heritage", "word_hi": "पारिवारिक धरोहर / संस्कार", "meaning": "Values, customs, and good manners passed down by elders."},
            {"word_en": "Resemblance", "word_hi": "शारीरिक समानता", "meaning": "Looking similar to family members in face, hair, or habits."},
            {"word_en": "Cooperation", "word_hi": "सहयोग / मिलजुलकर काम", "meaning": "Working together harmoniously as a team."}
        ],
        "activity": {
            "title": "My Family Tree & Resemblance Chart",
            "instructions": "Draw a tree with names of family elders. Note down one feature (smile, eyes, singing) you share with your mother or grandfather."
        },
        "questions": [
            {
                "question_en": "Why is the family called our first school?",
                "question_hi": "परिवार को हमारा पहला स्कूल क्यों कहा जाता है?",
                "answer_en": "Because we learn our mother tongue, moral values, and life habits from our family before going to school.",
                "answer_hi": "क्योंकि हम स्कूल जाने से पहले अपनी मातृभाषा, अच्छे संस्कार और आदतें अपने परिवार से सीखते हैं।"
            }
        ]
    },

    "chhotu_house": {
        "summary_en": "A house provides essential shelter from sun, cold winds, rain, wild animals, and thieves. Houses are divided into functional spaces: kitchen, sleeping area, veranda, and courtyard. Animals also share our houses.",
        "summary_hi": "घर हमें धूप, ठंड, बारिश और जंगली जानवरों से सुरक्षा प्रदान करता है। घर में रसोई, शयन कक्ष और आंगन जैसे अलग-अलग हिस्से होते हैं। कुछ जीव बिन बुलाए मेहमान बनकर भी हमारे घर में रहते हैं।",
        "key_points": [
            "Purpose of Shelter: Safety, comfort, warmth, and family living.",
            "Parts of a House: Kitchen for cooking, bedroom for resting, courtyard/veranda for gathering.",
            "Uninvited Guests: Lizards, spiders, mice, and ants that live in corners and crevices.",
            "Cleanliness: Regular sweeping, dusting, and proper disposal of garbage prevent pests and sickness."
        ],
        "vocabulary": [
            {"word_en": "Shelter", "word_hi": "आश्रय / निवास", "meaning": "A safe dwelling that protects humans and creatures from weather hazards."},
            {"word_en": "Courtyard", "word_hi": "आंगन", "meaning": "An open space enclosed by walls inside a traditional village house."},
            {"word_en": "Hygiene", "word_hi": "स्वच्छता", "meaning": "Practices conducive to maintaining health and preventing disease through cleanliness."}
        ],
        "activity": {
            "title": "Clean Home Floor Plan Drawing",
            "instructions": "Draw your dream house on a slate. Mark the kitchen, water area, dustbin spot, and front doorway decorated with traditional floral Rangoli."
        },
        "questions": [
            {
                "question_en": "Name two animals that live in our houses without being invited.",
                "question_hi": "ऐसे दो जीवों के नाम बताइए जो बिना बुलाए मेहमान की तरह हमारे घर में रहते हैं?",
                "answer_en": "House lizards on walls and mice in kitchen corners.",
                "answer_hi": "दीवारों पर छिपकलियाँ और कोनों में छोटे चूहे।"
            }
        ]
    },

    "foods_we_eat": {
        "summary_en": "Food gives us vital energy to play, study, and grow. Different regions eat varied staple grains: rice in eastern India, wheat in northern plains, and nutritious millets like Marua (Ragi) in Jharkhand.",
        "summary_hi": "भोजन हमें काम करने, खेलने और बढ़ने की ऊर्जा देता है। अलग-अलग स्थानों पर खान-पान अलग होता है: झारखंड में चावल और मडुआ (रागी) की रोटी मुख्य पौष्टिक आहार हैं।",
        "key_points": [
            "Food Groups: Energy-giving (rice, wheat), Body-building (pulses, milk), Protective (fruits, green vegetables).",
            "Age-Appropriate Food: Infants drink milk; children eat khichdi and lentils; elders prefer soft digested meals.",
            "Jharkhand Staples: Marua roti, Mahua preparations, leafy greens (Gendhari, Koinar saag), and steamed Pitha.",
            "No Food Wastage: Take only what you can finish on your plate."
        ],
        "vocabulary": [
            {"word_en": "Nutrients", "word_hi": "पोषक तत्व", "meaning": "Substances in food that the body needs to function, grow, and heal."},
            {"word_en": "Staple Grain", "word_hi": "मुख्य अन्न / अनाज", "meaning": "The primary grain consumed regularly by people in a region."},
            {"word_en": "Balanced Diet", "word_hi": "संतुलित आहार", "meaning": "A meal containing right proportions of cereals, pulses, vegetables, and milk."}
        ],
        "activity": {
            "title": "Mid-Day Meal Rainbow Plate",
            "instructions": "List foods on your Mid-Day Meal plate. Identify yellow lentils, green seasonal leafy vegetables, and white steamed rice."
        },
        "questions": [
            {
                "question_en": "Why do 4-month-old infants only consume mother's milk?",
                "question_hi": "चार महीने के छोटे बच्चे केवल मां का दूध ही क्यों पीते हैं?",
                "answer_en": "Because infants have no teeth to chew solid foods and mother's milk provides complete nutrition.",
                "answer_hi": "क्योंकि शिशुओं के दांत नहीं होते और मां का दूध उनके शरीर के लिए संपूर्ण पोषण देता है।"
            }
        ]
    },

    "saying_without_speaking": {
        "summary_en": "We express feelings not only through spoken words, but also through facial expressions, body gestures, dance mudras, and sign language. We should be inclusive and supportive of children with special needs.",
        "summary_hi": "हम केवल बोलकर ही नहीं, बल्कि चेहरे के भावों, हाथों के इशारों (मुद्राओं) और सांकेतिक भाषा से भी अपनी बात कहते हैं। हमें विशेष आवश्यकता वाले बच्चों का सम्मान करना चाहिए।",
        "key_points": [
            "Non-Verbal Communication: Smiles show happiness; lowered eyes show sadness; wide eyes show surprise.",
            "Sign Language: Hand shapes and spatial movements enabling hearing-impaired people to communicate fluidly.",
            "Dance Mudras: Classical Indian and folk tribal dances use hand mudras to represent flowers, birds, and rivers.",
            "Empathy: Treat every classmate with kindness regardless of physical abilities."
        ],
        "vocabulary": [
            {"word_en": "Expression", "word_hi": "भाव-भंगिमा", "meaning": "Conveying thoughts and emotions through facial gestures and postures."},
            {"word_en": "Sign Language", "word_hi": "सांकेतिक भाषा", "meaning": "Visual communication using hand signs, gestures, and facial expressions."},
            {"word_en": "Mudra", "word_hi": "हस्त मुद्रा", "meaning": "Symbolic hand gesture used in traditional dances and storytelling."}
        ],
        "activity": {
            "title": "Dumb Charades / Emotion Acting",
            "instructions": "One student acts out an action (drinking water, feeling cold, scoring a goal) without uttering any sound. The class guesses the meaning."
        },
        "questions": [
            {
                "question_en": "How can you tell if someone is angry or happy without them saying a word?",
                "question_hi": "बिना बोले आप कैसे समझ सकते हैं कि कोई व्यक्ति खुश है या गुस्सा?",
                "answer_en": "By looking at their facial expressions: smiling eyes indicate happiness, while furrowed brows show anger.",
                "answer_hi": "उनके चेहरे के भावों से: मुस्कुराता चेहरा खुशी दिखाता है और चढ़ी हुई भौंहें गुस्सा।"
            }
        ]
    },

    "flying_high": {
        "summary_en": "Birds possess distinct beaks, claws, feathers, and calls adapted to their dietary habits. Woodpeckers have chisel beaks to catch tree bark insects; eagles have hooked beaks to tear meat; ducks have flat beaks with strainers.",
        "summary_hi": "पक्षियों की चोंच, पंजे और पंख उनके खान-पान के अनुसार अलग-अलग होते हैं। कठफोड़वा की चोंच छैनी जैसी होती है, चील की मुड़ी हुई और बत्तख की चपटी छलनी जैसी होती है।",
        "key_points": [
            "Beak Adaptations: Hooked (predators), long & pointed (nectar sippers), flat & broad (water birds).",
            "Feet & Claws: Perching birds (sparrows grip twigs), webbed feet (ducks swim), talons (owls catch prey).",
            "Feathers Function: Flight feathers aid flying; down feathers provide body insulation and warmth.",
            "Our Bird Friends: Peacocks (National Bird), Koel (melodious singer), Crow (scavenger keeping grounds clean)."
        ],
        "vocabulary": [
            {"word_en": "Beak / Bill", "word_hi": "चोंच", "meaning": "Bird's hard mouthparts used for eating, preening, building nests, and defense."},
            {"word_en": "Talons", "word_hi": "शिकारी पंजे", "meaning": "Sharp hooked claws of birds of prey like eagles and hawks."},
            {"word_en": "Webbed Feet", "word_hi": "झिल्लीदार पैर", "meaning": "Skin connecting toes in water birds like ducks that acts as oars for swimming."}
        ],
        "activity": {
            "title": "Beak Matching & Feather Collection",
            "instructions": "Collect shed bird feathers from garden soil. Examine the central shaft and soft barbs under a magnifying lens."
        },
        "questions": [
            {
                "question_en": "Why do ducks have flat beaks with tiny holes on the edges?",
                "question_hi": "बत्तखों की चोंच चपटी और किनारों पर छोटे छेदों वाली क्यों होती है?",
                "answer_en": "The flat beak scoops water and mud; muddy water drains out through holes leaving insects and worms inside to eat.",
                "answer_hi": "कीचड़ और पानी को छानने के लिए; पानी बाहर निकल जाता है और कीड़े चोंच में रह जाते हैं।"
            }
        ]
    },

    "its_raining": {
        "summary_en": "Rain brings relief after the scorching summer heat. Clouds form when sun heats water bodies. Rain revives parched paddy fields, fills dried streams, and creates vibrant rainbows.",
        "summary_hi": "बारिश भीषण गर्मी के बाद शीतलता लाती है। सूरज की गर्मी से जलवाष्प बनकर बादल बनते हैं। वर्षा से सूखे खेत लहलहाते हैं, नदियां भर जाती हैं और आकाश में इंद्रधनुष दिखाई देता है।",
        "key_points": [
            "Cloud Formation: Invisible water vapor rises high in cold atmosphere and condenses into cloud droplets.",
            "Monsoon Season: Southwest monsoon winds bring life-giving rains to Jharkhand from June to September.",
            "Rainbow Phenomenon: Sunlight passing through raindrop prisms splits into 7 vibrant colors (VIBGYOR).",
            "Farmers & Agriculture: Farmers welcome rains to plant Kharif crops like paddy (Dhan) and maize."
        ],
        "vocabulary": [
            {"word_en": "Monsoon", "word_hi": "मानसून / वर्षा ऋतु", "meaning": "Seasonal prevailing wind bringing heavy rainfall across the subcontinent."},
            {"word_en": "Condensation", "word_hi": "वाष्प का जमना / संघनन", "meaning": "Transformation of vapor back into liquid water droplets."},
            {"word_en": "Rainbow", "word_hi": "इंद्रधनुष", "meaning": "An optical arch of seven spectral colors formed by dispersion of sunlight through raindrops."}
        ],
        "activity": {
            "title": "Rainbow Colors Rhyme (VIBGYOR)",
            "instructions": "Draw an arch of seven colors on paper: Violet, Indigo, Blue, Green, Yellow, Orange, Red. Write the name of each color."
        },
        "questions": [
            {
                "question_en": "Why do village farmers rejoice when dark monsoon clouds appear?",
                "question_hi": "काले मानसूनी बादलों को देखकर किसान खुश क्यों होते हैं?",
                "answer_en": "Rainwater is essential to irrigate paddy fields and ensure a bountiful harvest of food grains.",
                "answer_hi": "क्योंकि बारिश का पानी धान की खेती और अच्छी फसल के लिए सबसे जरूरी होता है।"
            }
        ]
    },

    "what_is_cooking": {
        "summary_en": "Cooking makes food tender, palatable, easily digestible, and eliminates harmful bacteria. Food is prepared using diverse methods: boiling, roasting, frying, steaming, and baking.",
        "summary_hi": "पकाने से भोजन मुलायम, स्वादिष्ट और सुपाच्य बनता है तथा हानिकारक कीटाणु नष्ट होते हैं। भोजन उबालकर, भूनकर, तलकर, भाप में और सेंककर तैयार किया जाता है।",
        "key_points": [
            "Cooking Techniques: Boiling (rice, potatoes), Steaming (idli, dhokla), Roasting (roti, corn), Frying (puri, pakora).",
            "Utensil Materials: Clay pots (handi), iron woks (kadhai), brass, stainless steel, and pressure cookers.",
            "Cooking Fuels: Solar cookers (clean sunlight), LPG gas cylinders, biogas, and wood/cow-dung stoves.",
            "Kitchen Safety: Never play near gas stoves, burning firewood, or hot boiling oil."
        ],
        "vocabulary": [
            {"word_en": "Digestion", "word_hi": "पाचन", "meaning": "The bodily process of breaking down food into substances that can be absorbed."},
            {"word_en": "Steaming", "word_hi": "भाप में पकाना", "meaning": "Cooking food by surrounding it with steam, preserving vital vitamins."},
            {"word_en": "Solar Cooker", "word_hi": "सौर चूल्हा", "meaning": "An eco-friendly device that utilizes direct sunlight energy to cook meals without smoke."}
        ],
        "activity": {
            "title": "No-Flame Snack Preparation (Sprout Salad)",
            "instructions": "Mix soaked gram/moong sprouts with chopped cucumber, tomato, coriander, a pinch of salt, and lemon juice. Enjoy healthy food made without fire!"
        },
        "questions": [
            {
                "question_en": "Why is steaming considered a healthier way of cooking than deep frying?",
                "question_hi": "गहरे तेल में तलने की तुलना में भाप में पकाना अधिक स्वास्थ्यवर्धक क्यों माना जाता है?",
                "answer_en": "Steaming uses no excess oil and preserves natural vitamins and nutrients in the food.",
                "answer_hi": "क्योंकि भाप में पकाने में अतिरिक्त तेल नहीं लगता और भोजन के प्राकृतिक पोषक तत्व सुरक्षित रहते हैं।"
            }
        ]
    },

    # --- English Reader Chapters ---
    "good_morning": {
        "summary_en": "A joyful child awakens at dawn and greets the vast sky, warm morning sun, gentle breezes, songbirds, blooming trees, and creeping green grass, celebrating a new day of play and discovery.",
        "summary_hi": "एक प्रसन्न बच्चा भोर में जागकर नीले आकाश, चमकते सूरज, मंद हवाओं, चहकते पक्षियों और हरी घास को 'सुप्रभात' कहता है और नए दिन के आनंद में शामिल होता है।",
        "key_points": [
            "Poetic Tone: Cheerful, observant, and welcoming towards nature and living creatures.",
            "Rhyme & Rhythm: Sun/Run, Day/Play, Away/Creeping grass.",
            "Healthy Morning Habits: Waking early, greeting elders with Johar / Good Morning, breathing fresh outdoor air.",
            "Gratitude: Thanking the natural world that sustains life around us."
        ],
        "vocabulary": [
            {"word_en": "Wide Awake", "word_hi": "पूरी तरह जागा हुआ", "meaning": "Fully conscious and alert, ready to learn with energy."},
            {"word_en": "Creeping Grass", "word_hi": "जमीन पर फैलने वाली दूब घास", "meaning": "Grass that spreads close to the soil surface."},
            {"word_en": "Breeze", "word_hi": "मंद शीतल हवा", "meaning": "A gentle, refreshing, pleasant wind."}
        ],
        "activity": {
            "title": "Morning Greeting Circle",
            "instructions": "Greet three classmates using different greetings: 'Good morning!', 'Johar!', and 'Namaskar!' with a warm smile."
        },
        "questions": [
            {
                "question_en": "Why is the child in the poem happy?",
                "question_hi": "कविता में बच्चा इतना खुश क्यों है?",
                "answer_en": "Because night is over, morning has arrived, and the child is eager to go outside and play with nature.",
                "answer_hi": "क्योंकि रात बीत चुकी है, सुबह हो गई है और बच्चा बाहर जाकर प्रकृति के साथ खेलना चाहता है।"
            }
        ]
    },

    "magic_garden": {
        "summary_en": "The magic garden situated in a school playground was truly special because its sunflowers, roses, marigolds, and poppies were lovingly tended by school children. Birds loved the children who brought bread crumbs.",
        "summary_hi": "स्कूल के मैदान में स्थित जादुई बगीचा बेहद सुंदर था क्योंकि बच्चे फूलों को पानी देते थे और चिड़ियों को प्यार से रोटी के टुकड़े खिलाते थे। फूल बच्चों की हंसी सुनकर खिल उठते थे।",
        "key_points": [
            "Compassion for Nature: Plants thrive when children water their roots and treat them with gentle care.",
            "Flower Varieties: Tall Sunflowers, fragrant Roses, golden Marigolds, red Poppies, and Pansies.",
            "Symbiosis: Birds protect garden plants from harmful insects while children provide crumbs and water."
        ],
        "vocabulary": [
            {"word_en": "Playground", "word_hi": "खेल का मैदान", "meaning": "An outdoor area provided for children to play at school."},
            {"word_en": "Thirsty Roots", "word_hi": "प्यासी जड़ें", "meaning": "Plant roots beneath dry soil needing watering."},
            {"word_en": "Tiny Fairies", "word_hi": "नन्हीं परियां", "meaning": "Imaginary magical beings with wings adorned with flower petals."}
        ],
        "activity": {
            "title": "School Plant Adoption",
            "instructions": "Choose one plant or shrub in the school yard. Give it a cup of clean water each morning and watch its green buds unfurl."
        },
        "questions": [
            {
                "question_en": "Why did the flowers in the garden love the little children?",
                "question_hi": "बगीचे के फूल छोटे बच्चों को इतना प्यार क्यों करते थे?",
                "answer_en": "Because the kind children brought water for their thirsty roots and loosened the soil around them.",
                "answer_hi": "क्योंकि दयालु बच्चे उनकी जड़ों में पानी डालते थे और मिट्टी की देखभाल करते थे।"
            }
        ]
    },

    "bird_talk": {
        "summary_en": "Two birds, Robin and Jay, sit on a branch discussing how peculiar humans appear. Humans have no feathers, do not sit on telephone wires, and cannot fly gracefully through the sky.",
        "summary_hi": "रॉबिन और जे नाम के दो पक्षी डाल पर बैठकर बातें करते हैं कि इंसान कितने अजीब हैं! उनके पंख नहीं होते, वे तारों पर नहीं बैठ सकते और आसमान में उड़ नहीं सकते।",
        "key_points": [
            "Perspective: Seeing human habits from an animal's viewpoint teaches empathy and humor.",
            "Bird Characteristics: Feathers, wings, beaks, light hollow bones, perching habits.",
            "Dialogue Appreciation: Understanding back-and-forth conversation between characters in literature."
        ],
        "vocabulary": [
            {"word_en": "Beetles", "word_hi": "भृंग / गुबरैला", "meaning": "Hard-shelled insects that birds forage for nutrition."},
            {"word_en": "Feathers", "word_hi": "पंख", "meaning": "Light plumage covering bird bodies that enables flight."},
            {"word_en": "Wires", "word_hi": "बिजली या टेलीफोन के तार", "meaning": "Thin metal cables stretched between poles where birds perch."}
        ],
        "activity": {
            "title": "Bird Dialogue Roleplay",
            "instructions": "Two students act as Robin and Jay, chirping and wondering why human children walk on two legs without flying."
        },
        "questions": [
            {
                "question_en": "What three things can birds do that human beings cannot do?",
                "question_hi": "ऐसी कौन सी तीन बातें हैं जो पक्षी कर सकते हैं लेकिन मनुष्य नहीं कर सकते?",
                "answer_en": "Birds can grow feathers, perch easily on thin wires, and fly without engines in the open sky.",
                "answer_hi": "पक्षी पंख उगा सकते हैं, पतले तारों पर बैठ सकते हैं और बिना मशीन के आसमान में उड़ सकते हैं।"
            }
        ]
    },

    "nina_baby_sparrows": {
        "summary_en": "Nina is reluctant to attend her aunt's wedding in Delhi because she worries that leaving the house locked will starve two newborn baby sparrows nesting on her room bookshelf. Her mother lovingly finds a solution by leaving the window open.",
        "summary_hi": "नीना दिल्ली में अपनी मौसी की शादी में जाने से उदास थी क्योंकि कमरे का ताला बंद होने से उसकी अलमारी पर बने घोंसले में रहने वाले नन्हें गौरैया के बच्चे भूखे रह जाते। मां ने खिड़की खुली रखकर समस्या हल की।",
        "key_points": [
            "Compassion & Empathy: Nina prioritizes the welfare of tiny vulnerable birds over party clothes.",
            "Bird Parental Care: Mother and father sparrows hunt constantly to feed plump newborn nestlings.",
            "Problem Solving: Mother's wise idea of unbolting the window allows sparrows to fly in and out freely."
        ],
        "vocabulary": [
            {"word_en": "Nestlings", "word_hi": "नन्हें चूजे / घोंसले के बच्चे", "meaning": "Young birds that have not yet grown flight feathers to leave the nest."},
            {"word_en": "Plump", "word_hi": "गोल-मटोल / हष्ट-पुष्ट", "meaning": "Pleasantly fat and healthy."},
            {"word_en": "Relief", "word_hi": "राहत / चैन", "meaning": "A feeling of reassurance and relaxation following release from anxiety."}
        ],
        "activity": {
            "title": "Clay Bird Water Feeder",
            "instructions": "Place a shallow clay bowl of fresh water under a shady tree in the schoolyard so thirsty village birds can drink safely."
        },
        "questions": [
            {
                "question_en": "Why was Nina reluctant to lock her bedroom door and travel to Delhi?",
                "question_hi": "नीना कमरे में ताला लगाकर दिल्ली जाने के लिए तैयार क्यों नहीं थी?",
                "answer_en": "She was worried that mother and father sparrow would not be able to enter to feed their baby nestlings.",
                "answer_hi": "उसे चिंता थी कि ताला बंद होने पर चिड़िया के माता-पिता नन्हें बच्चों को दाना खिलाने अंदर नहीं आ पाएंगे।"
            }
        ]
    },

    "little_by_little": {
        "summary_en": "A tiny acorn buried deep in dark soil quietly grows year after year. It sends slender roots downward to drink water and pushes a green shoot upward into sunlight, eventually becoming a mighty mighty oak tree.",
        "summary_hi": "मिट्टी में दबा छोटा सा बांज (ओक) का बीज धीरे-धीरे वर्षों में बढ़ता है। जड़ें नीचे पानी की खोज में जाती हैं और तना ऊपर धूप की ओर उठता है, अंततः वह एक विशाल छायादार वृक्ष बन जाता है।",
        "key_points": [
            "Perseverance & Patience: Great achievements and learning grow little by little through daily dedicated effort.",
            "Plant Germination: Seed coats soften with moisture; roots emerge first (downward), followed by plumule (shoot).",
            "Forest Giants: Majestic trees that shield village cattle and birds started from tiny seeds."
        ],
        "vocabulary": [
            {"word_en": "Acorn", "word_hi": "बांज का बीज / फल", "meaning": "Small oval nut of the oak tree."},
            {"word_en": "Slender Root", "word_hi": "पतली कोमल जड़", "meaning": "Delicate young root thread absorbing soil nutrients."},
            {"word_en": "Mighty", "word_hi": "विशाल / शक्तिशाली", "meaning": "Possessing great size, strength, and endurance."}
        ],
        "activity": {
            "title": "Sprouting Seed Germination Log",
            "instructions": "Wrap a bean seed in moist cotton. Measure the root growth in millimeters every day for 5 days."
        },
        "questions": [
            {
                "question_en": "What moral lesson does the acorn's growth teach primary school students?",
                "question_hi": "बीज के बढ़ने की प्रक्रिया बच्चों को क्या नैतिक सीख देती है?",
                "answer_en": "Even small efforts done consistently every single day can help a child grow into a wise, strong person.",
                "answer_hi": "प्रतिदिन का छोटा-सा प्रयास भी बच्चे को एक दिन महान, बुद्धिमान और मजबूत इंसान बनाता है।"
            }
        ]
    },

    "enormous_turnip": {
        "summary_en": "An old man plants turnip seeds. One turnip grows colossal and cannot be pulled out by the old man alone. Only when the old woman, a boy, and a girl unite their strength together do they successfully uproot the enormous turnip.",
        "summary_hi": "एक बूढ़े किसान ने शलजम का बीज बोया। वह इतना विशाल हो गया कि अकेला किसान उसे उखाड़ नहीं सका। जब बूढ़ी औरत, एक लड़का और एक लड़की सबने मिलकर जोर लगाया, तब जाकर भारी शलजम निकला।",
        "key_points": [
            "Unity is Strength: Difficult challenges that defeat one person are easily solved when people cooperate.",
            "Root Vegetables: Turnips, carrots, radishes, and beetroots store rich carbohydrates below the soil.",
            "Community Spirit: Celebrating victory together with a wholesome shared meal."
        ],
        "vocabulary": [
            {"word_en": "Enormous", "word_hi": "विशालकाय / बहुत बड़ा", "meaning": "Extremely large in size, volume, or quantity."},
            {"word_en": "Turnip", "word_hi": "शलजम", "meaning": "A round root vegetable with white and purple skin grown in winter."},
            {"word_en": "Uproot", "word_hi": "जड़ से उखाड़ना", "meaning": "Pulling a plant completely out of the ground along with its roots."}
        ],
        "activity": {
            "title": "Tug-of-War & Teamwork Demonstration",
            "instructions": "Conduct a light tug-of-war game with safe rope to demonstrate how combined pull overcomes resistance."
        },
        "questions": [
            {
                "question_en": "Who helped the old man pull out the enormous turnip from the garden?",
                "question_hi": "बूढ़े व्यक्ति को विशाल शलजम उखाड़ने में किस-किसने मदद की?",
                "answer_en": "An old woman, a young schoolboy, and a little girl joined hands together to pull it out.",
                "answer_hi": "एक बूढ़ी महिला, एक छोटे लड़के और एक नन्हीं लड़की ने मिलकर मदद की।"
            }
        ]
    },

    # --- Fallback / General Grade 3 Context ---
    "default_science": {
        "summary_en": "Environmental Studies for Primary Class 3 nurtures scientific curiosity about living organisms, our village ecosystem, weather changes, and sustainable environmental guardianship.",
        "summary_hi": "कक्षा 3 का पर्यावरण अध्ययन बच्चों में अपने आस-पास के पेड़-पौधों, पशु-पक्षियों, मौसम और प्रकृति की देखभाल के प्रति वैज्ञानिक दृष्टिकोण विकसित करता है।",
        "key_points": [
            "Curiosity: Asking respectful questions about how plants drink and how insects communicate.",
            "Ecosystem Conservation: Protecting clean village streams, sacred groves (Jaherthan), and soil fertility.",
            "Community Health: Washing hands before meals and keeping village surroundings clean."
        ],
        "vocabulary": [
            {"word_en": "Environment", "word_hi": "पर्यावरण", "meaning": "The natural world encompassing living and non-living elements around us."},
            {"word_en": "Ecosystem", "word_hi": "पारिस्थितिकी तंत्र", "meaning": "A biological community of interacting organisms and their physical environment."}
        ],
        "activity": {
            "title": "Nature Scavenger Hunt",
            "instructions": "Find one smooth stone, one dry fallen leaf, and one blade of grass. Describe them using sensory words."
        },
        "questions": [
            {
                "question_en": "Why should we plant indigenous trees like Sal and Neem around our school?",
                "question_hi": "हमें अपने विद्यालय के चारों ओर साल और नीम जैसे स्थानीय पेड़ क्यों लगाने चाहिए?",
                "answer_en": "They give abundant shade, clean the air, stop soil erosion, and shelter friendly birds.",
                "answer_hi": "वे शीतल छाया देते हैं, हवा को शुद्ध करते हैं, मिट्टी के कटाव को रोकते हैं और पक्षियों को बसेरा देते हैं।"
            }
        ]
    },

    "default_english": {
        "summary_en": "Primary English literature develops phonics, conversational fluency, vocabulary acquisition, and moral values through engaging bilingual stories, nature poems, and classroom dialogues.",
        "summary_hi": "प्राथमिक अंग्रेजी शिक्षण कहानियों, कविताओं और मातृभाषा के माध्यम से बच्चों में आत्मविश्वास, शब्द ज्ञान और अभिव्यक्ति क्षमता का विकास करता है।",
        "key_points": [
            "Clear Phonics: Pronouncing consonants and vowels with joyful musical rhythm.",
            "Mother Tongue Bridging: Connecting English terms with Santali, Ho, Mundari, and Hindi equivalents.",
            "Storytelling: Retelling simple story sequences using beginning, middle, and end structure."
        ],
        "vocabulary": [
            {"word_en": "Dialogue", "word_hi": "बातचीत / संवाद", "meaning": "Conversation between two or more people."},
            {"word_en": "Adjective", "word_hi": "विशेषण", "meaning": "Describing words that paint pictures of size, color, and feelings."}
        ],
        "activity": {
            "title": "Bilingual Story Echo",
            "instructions": "Teacher says an English phrase; students repeat it and immediately echo its vernacular mother tongue equivalent."
        },
        "questions": [
            {
                "question_en": "How does listening to stories help young learners?",
                "question_hi": "कहानियां सुनने से बच्चों को क्या लाभ होता है?",
                "answer_en": "Stories spark imagination, teach new words, and cultivate empathy for all living beings.",
                "answer_hi": "कहानियां कल्पनाशीलता को जगाती हैं, नए शब्द सिखाती हैं और अच्छे संस्कार देती हैं।"
            }
        ]
    }
}


def get_curriculum_knowledge(lesson_title: str, subject: str = "") -> dict:
    title_lower = lesson_title.lower()
    
    # Exact and semantic matching for all 19 Class 3 Chapters
    if "poonam" in title_lower or "day out" in title_lower:
        return JCERT_KNOWLEDGE_BASE["poonam"]
    elif "fairy" in title_lower or "plant" in title_lower:
        return JCERT_KNOWLEDGE_BASE["plant_fairy"]
    elif "water o' water" in title_lower or "water o water" in title_lower or "पानी रे पानी" in title_lower:
        return JCERT_KNOWLEDGE_BASE["water"]
    elif "first school" in title_lower or "पहला स्कूल" in title_lower or "family" in title_lower:
        return JCERT_KNOWLEDGE_BASE["our_first_school"]
    elif "chhotu" in title_lower or "छोटू" in title_lower or "house" in title_lower or "shelter" in title_lower:
        return JCERT_KNOWLEDGE_BASE["chhotu_house"]
    elif "foods we eat" in title_lower or "खाना अपना" in title_lower or "food" in title_lower:
        return JCERT_KNOWLEDGE_BASE["foods_we_eat"]
    elif "saying without speaking" in title_lower or "बिन बोले" in title_lower or "sign" in title_lower:
        return JCERT_KNOWLEDGE_BASE["saying_without_speaking"]
    elif "flying high" in title_lower or "पंख फैलाएं" in title_lower or "bird" in title_lower and "talk" not in title_lower:
        return JCERT_KNOWLEDGE_BASE["flying_high"]
    elif "raining" in title_lower or "बादल आए" in title_lower or "rain" in title_lower:
        return JCERT_KNOWLEDGE_BASE["its_raining"]
    elif "cooking" in title_lower or "पकाएं" in title_lower or "kitchen" in title_lower:
        return JCERT_KNOWLEDGE_BASE["what_is_cooking"]
    elif "good morning" in title_lower or "सुप्रभात" in title_lower:
        return JCERT_KNOWLEDGE_BASE["good_morning"]
    elif "magic garden" in title_lower or "जादुई बगीचा" in title_lower:
        return JCERT_KNOWLEDGE_BASE["magic_garden"]
    elif "bird talk" in title_lower or "robin" in title_lower:
        return JCERT_KNOWLEDGE_BASE["bird_talk"]
    elif "nina" in title_lower or "sparrow" in title_lower:
        return JCERT_KNOWLEDGE_BASE["nina_baby_sparrows"]
    elif "little by little" in title_lower or "acorn" in title_lower:
        return JCERT_KNOWLEDGE_BASE["little_by_little"]
    elif "turnip" in title_lower or "शलजम" in title_lower or "enormous" in title_lower:
        return JCERT_KNOWLEDGE_BASE["enormous_turnip"]
    elif "english" in title_lower or "reader" in title_lower or "unit" in title_lower or "english" in subject.lower():
        return JCERT_KNOWLEDGE_BASE["default_english"]
    else:
        return JCERT_KNOWLEDGE_BASE["default_science"]


def call_gemini_api(prompt: str, api_key: str) -> dict | None:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.2,
            "responseMimeType": "application/json"
        }
    }
    try:
        r = requests.post(url, json=payload, timeout=25)
        if r.status_code == 200:
            text = r.json()["candidates"][0]["content"]["parts"][0]["text"]
            return json.loads(text)
        else:
            print(f"[WARN] Gemini status {r.status_code}: {r.text[:200]}")
    except Exception as e:
        print(f"[WARN] Gemini call error: {e}")
    return None


def call_groq_or_qwen_api(prompt: str, api_key: str, model: str = "qwen-2.5-32b") -> dict | None:
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    payload = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are an expert bilingual primary school curriculum pedagogue for Jharkhand schools (JCERT / CBSE). "
                    "Provide accurate, age-appropriate, child-friendly educational content. Output strictly valid JSON."
                )
            },
            {"role": "user", "content": prompt}
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.2
    }
    try:
        r = requests.post(url, headers=headers, json=payload, timeout=25)
        if r.status_code == 200:
            content = r.json()["choices"][0]["message"]["content"]
            return json.loads(content)
        else:
            print(f"[WARN] Groq/Qwen status {r.status_code}: {r.text[:200]}")
    except Exception as e:
        print(f"[WARN] Groq/Qwen call error: {e}")
    return None


def generate_notes_from_speech_session(
    transcripts: list[str],
    folder_title: str,
    target_language_name: str = "Santali",
    api_key: str | None = None,
    ai_provider: str = "gemini"
) -> dict:
    """Synthesizes teacher's spoken explanations and classroom translations
    into a structured, accurate study note with bilingual summary, key points,
    vocabulary, and review questions.
    """
    combined_speech = "\n".join([f"- {t}" for t in transcripts if t.strip()])
    if not combined_speech:
        combined_speech = "Teacher conducted oral discussion on core chapter concepts and everyday applications."

    prompt = f"""
Teacher's Spoken Classroom Lesson Transcript for Topic/Folder: "{folder_title}":
{combined_speech}

Target Vernacular Language: {target_language_name} (Jharkhand Primary School Education).

Please synthesize these spoken classroom explanations into a comprehensive, highly accurate study note for primary students.
Return strictly valid JSON with this exact structure:
{{
  "summary_en": "Accurate 2-3 sentence overview of what the teacher explained in clear simple English.",
  "summary_hi": "Exact Hindi translation of the summary for bilingual teachers.",
  "summary_vernacular": "Culturally authentic translation in {target_language_name}.",
  "key_points": [
    "Key learning objective or fact explained by teacher 1",
    "Key learning objective or fact explained by teacher 2",
    "Key learning objective or fact explained by teacher 3"
  ],
  "vocabulary": [
    {{"word_en": "English Term", "word_hi": "हिन्दी अर्थ", "meaning": "Simple child-friendly explanation."}},
    {{"word_en": "Second Term", "word_hi": "दूसरा शब्द", "meaning": "Simple child-friendly explanation."}}
  ],
  "activity": {{
    "title": "Classroom Activity based on teacher's spoken lesson",
    "instructions": "Hands-on activity children can do in school or at home."
  }},
  "questions": [
    {{
      "question_en": "Review question based on teacher's explanation?",
      "question_hi": "हिन्दी समीक्षा प्रश्न?",
      "answer_en": "Concise answer in English.",
      "answer_hi": "हिन्दी में उत्तर।"
    }}
  ]
}}
"""
    # 1. Try custom or env API key
    gemini_key = api_key if (ai_provider == "gemini" and api_key) else os.getenv("GEMINI_API_KEY")
    groq_key = api_key if (ai_provider in ["groq", "qwen"] and api_key) else os.getenv("GROQ_API_KEY")

    if gemini_key:
        res = call_gemini_api(prompt, gemini_key)
        if res and "summary_en" in res:
            return res

    if groq_key:
        res = call_groq_or_qwen_api(prompt, groq_key)
        if res and "summary_en" in res:
            return res

    # 2. Local fallback synthesis based on transcript
    return {
        "summary_en": f"In this classroom session on '{folder_title}', the teacher explained core ideas and vernacular vocabulary to help students understand the lesson deeply.",
        "summary_hi": f"इस कक्षा सत्र '{folder_title}' में शिक्षक ने विद्यार्थियों को मुख्य अवधारणाएं और मातृभाषा शब्दावली समझाई ताकि विषय को सरलता से समझा जा सके।",
        "summary_vernacular": f"ᱱᱚᱶᱟ ᱯᱟᱲᱦᱟᱣ ᱨᱮ '{folder_title}' ᱵᱟᱵᱚᱛ ᱢᱟᱪᱮᱫ ᱜᱚᱢᱠᱮ ᱥᱟᱱᱛᱟᱲᱤ ᱛᱮ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱼᱟᱭ ᱾",
        "key_points": [
            f"Classroom discussion focused on concepts of {folder_title}.",
            "Teacher guided students through mother tongue translations of key ideas.",
            "Students practiced speaking and listening to the lesson terms actively."
        ],
        "vocabulary": [
            {"word_en": folder_title, "word_hi": "पाठ का विषय", "meaning": "Central topic of today's classroom teaching session."}
        ],
        "activity": {
            "title": f"Review & Discussion on {folder_title}",
            "instructions": "Review the spoken sentences together in class and repeat the vernacular translations aloud."
        },
        "questions": [
            {
                "question_en": f"What was the main topic explained by the teacher during this session?",
                "question_hi": "शिक्षक द्वारा इस सत्र में क्या मुख्य विषय समझाया गया?",
                "answer_en": f"The teacher explained {folder_title} using bilingual classroom examples.",
                "answer_hi": f"शिक्षक ने द्विभाषी उदाहरणों के साथ {folder_title} का पाठ समझाया।"
            }
        ]
    }
