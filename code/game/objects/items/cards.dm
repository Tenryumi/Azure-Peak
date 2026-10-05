/datum/playingcard
	var/name = "playing card"
	var/card_icon = "card_back"
	var/back_icon = "card_back"

/datum/intent/hand/deal
	name = "deal"
	icon_state = "deal"

/datum/intent/hand/deal/faceup
	name = "deal (face-up)"
	icon_state = "deal-faceup"

/datum/intent/hand/deal/facedown
	name = "deal (face-down)"
	icon_state = "deal-faceup"

/obj/item/toy/cards/deck
	name = "deck of cards"
	desc = "A deck of simple playing cards inked in the name of one of Xylix's most favored activities."
	icon = 'icons/obj/toy.dmi'
	deckstyle = "syndicate"
	icon_state = "deck_syndicate_full"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0
	var/list/cards = list()
	grid_width = 32
	grid_height = 32
	possible_item_intents = list(/datum/intent/hand/deal/facedown, /datum/intent/hand/deal/faceup)

/// Returns whether or not the given user is able to access cheating mechanics.
/obj/item/toy/cards/deck/proc/can_user_cheat(mob/living/carbon/human/user)
	return TRUE

/obj/item/toy/cards/deck/get_mechanics_examine(mob/user)
	. = ..()
	. += span_smallnotice("I can CLICK-DRAG the deck into my hand slot to pick it up.")
	. += span_smallnotice("I may use this in my hand to choose whether to shuffle the deck, search it for specific cards to draw, or choose how many cards I wish to deal when dealing a hand.")
	. += span_smallnotice("While holding the deck, I may deal cards with a single click, which throws the card or cards to wherever I am aiming. LEFT CLICK deals a single card. RIGHT CLICK deals a hand of cards instead.")
	. += span_smallnotice("My intents determine whether or not I will deal the cards face-down or face-up.")
