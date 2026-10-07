#define TAROT_DECK_DESCRIPTION "The Mouthpiece of Xylix, given to mortals long ago. See fate. Never bend a corner."

/obj/item/deck/cards
	name = "deck of playing cards"
	desc = "To the Xylixians; sacred. To the rest of the church of the Ten; a source of moral decay."

/obj/item/deck/cards/get_new_deck()
	. = ..()
	for(var/suit in list("spades","clubs","diamonds","hearts"))
		for(var/number in list("ace","two","three","four","five","six","seven","eight","nine","ten","jack","queen","king"))
			var/datum/playingcard/pcard = new()
			pcard.name = "[capitalize(number)] of [capitalize(suit)]"
			pcard.front_icon_state = "[number]-[suit]"
			pcard.back_icon_state = back_icon_state
			pcard.icon = icon
			. += pcard // Make it so. // side note: I've been driving myself insane reworking cards LET ME HAVE MY FUN!!!! - Ryumi

/obj/item/deck/cards/triple
	name = "triple-sized deck of playing cards"
	deck_size = 3

/obj/item/deck/tarot
	name = "tarot deck (major arcana)"
	desc = TAROT_DECK_DESCRIPTION + " This deck uses only the major arcana."
	icon = 'icons/roguetown/items/cards/tarot.dmi'
	var/has_minor_arcana = FALSE

/obj/item/deck/tarot/includes_minor_arcana
	name = "tarot deck (major and minor arcana)"
	has_minor_arcana = TRUE
	desc = TAROT_DECK_DESCRIPTION + " This deck uses both the major and minor arcana."

/obj/item/deck/tarot/get_new_deck()
	. = ..()
	var/list/major_arcana = alist(
		"The Magician" = "magician",
		"The High Priestess" = "high-priestess",
		"The Empress" = "empress",
		"The Emperor" = "emperor",
		"The Hierophant" = "hierophant",
		"The Lovers" = "lovers",
		"The Chariot" = "chariot",
		"The Hermit" = "hermit",
		"The Wheel of Fortune" = "wheel-of-fortune",
		"The Hanged Man" = "hanged-man",
		"The Devil" = "devil",
		"The Tower" = "tower",
		"The Star" = "star",
		"The Moon" = "moon",
		"The Sun" = "sun",
		"The World" = "world",
		"The Fool" = "fool",
		"Justice" = "justice",
		"Strength" = "strength",
		"Death" = "death",
		"Temperance" = "temperance",
		"Judgement" = "judgement",
	)
	for(var/key, value in major_arcana)
		var/datum/playingcard/pcard = new()
		pcard.name = key
		pcard.front_icon_state = value
		pcard.back_icon_state = back_icon_state
		pcard.icon = icon
		. += pcard
	// If we want the minor arcana too, include that!
	if(has_minor_arcana)
		for(var/suit in list("swords","wands","cups","pentacles"))
			for(var/number in list("ace","two","three","four","five","six","seven","eight","nine","ten","page","knight","queen","king"))
				var/datum/playingcard/pcard = new()
				pcard.name = "[capitalize(number)] of [capitalize(suit)]"
				pcard.front_icon_state = "[number]-[suit]"
				pcard.back_icon_state = back_icon_state
				pcard.icon = icon
				. += pcard

#undef TAROT_DECK_DESCRIPTION
