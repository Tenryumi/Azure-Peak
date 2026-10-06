#define MAX_HAND_SIZE 10
#define TAROT_DECK_DESCRIPTION "The Mouthpiece of Xylix, given to mortals long ago. See fate. Never bend a corner."

/datum/playingcard
	var/name = "playing card"
	var/front_icon_state = "hand1"
	var/back_icon_state = "singlecard_down"
	/// If this is TRUE, the card will be rendered upside-down.
	var/reversed = FALSE
	var/icon = 'icons/roguetown/items/cards/playingcards.dmi'
	var/obj/item/deck/our_deck

/datum/playingcard/proc/get_card_image(image_loc, is_concealed)
	RETURN_TYPE(/image)
	return image(src.icon, image_loc, is_concealed ? back_icon_state : front_icon_state)

/datum/playingcard/proc/get_card_name()
	return name

// Card intents

/datum/intent/hand/deal
	name = "deal"
	icon_state = "indeal"

/datum/intent/hand/deal/faceup
	name = "deal (face-up)"
	icon_state = "indeal-faceup"

/datum/intent/hand/deal/facedown
	name = "deal (face-down)"
	icon_state = "indeal-facedown"

// Hand of cards. Holds one or more cards

/obj/item/card_hand
	name = "hand of cards"
	icon = 'icons/roguetown/items/cards/playingcards.dmi'
	icon_state = null
	dropshrink = 0.5
	var/list/datum/playingcard/cards = list()
	/// The original deck we come from. Our cards can ONLY be taken from / put into this deck, and no other.
	var/obj/item/deck/our_deck = null
	var/concealed = TRUE

/obj/item/card_hand/attackby(obj/item/I, mob/user, params)
	if(!user || !ishuman(user) || user.stat)
		return
	if(istype(I, /obj/item/card_hand))
		var/obj/item/card_hand/CH = I
		if(MAX_HAND_SIZE < (CH.cards.len + cards.len))
			to_chat(user, span_warning("\The [src] can only hold [MAX_HAND_SIZE] cards at most."))
			return
		var/mob/living/carbon/human/H = user
		cards.Add(CH.cards)
		H.visible_message(span_notice("\The [H] joins \the [CH] with [H.p_their()] hand."))
		qdel(CH)
		update_icon()

/obj/item/card_hand/attack_self(mob/user)
	. = ..()
	concealed = !concealed
	update_icon()
	user.visible_message(span_notice("\The [user] [concealed ? "conceals" : "reveals"] [user.p_their()] hand."), span_notice("I [concealed ? "conceal" : "reveal"] my hand."), span_notice("I hear the flipping of card stock."))

/obj/item/card_hand/examine(mob/user)
	. = ..()
	if((!concealed) && cards.len)
		. += "<details><summary>[span_notice("Cards in Hand:")]</summary>"
		for(var/datum/playingcard/C in cards)
			var/image/I = C.get_card_image(user, FALSE)
			. += span_notice("[icon2html(I, user)] [C.get_card_name()]")
		. += "</details>"

/obj/item/card_hand/update_icon()
	cut_overlays()

	var/cardCount = cards.len
	if(!cardCount)
		qdel(src)
		return
	else if(cardCount > 1)
		name = "hand of cards ([cardCount])"
		desc = "The inked illustrations, still as ice, await their wielder's moment of glory and fortune."
	else
		name = "playing card"
		desc = "One would be forgiven for the bizarre impulse to flick the card stock in one's hand." // Stimming...

	if(cardCount == 1)
		var/datum/playingcard/P = cards[1]
		var/image/I = P.get_card_image(src, concealed)
		add_overlay(I)
		return

	var/offset = FLOOR(20/cardCount, 1)

	var/i = 0
	for(var/datum/playingcard/P in cards)
		var/image/I = P.get_card_image(src, concealed)
		I.pixel_x = -7+(offset*i)
		add_overlay(I)
		i++

/obj/item/card_hand/pickup(mob/user)
	. = ..()
	update_icon()

/obj/item/card_hand/AltClick(mob/user)
	. = ..()


/obj/item/card_hand/proc/remove_card(mob/living/carbon/user)
	if(!user || user.stat)
		return

/obj/item/card_hand/Initialize(mapload, obj/item/deck/source_deck, list/_cards)
	. = ..()
	if(!source_deck || !_cards?.len)
		qdel(src)
		return
	src.our_deck = source_deck
	src.cards.Insert(1, _cards)
	update_icon()

// Card decks

// Abstract card deck. Do not directly spawn this ingame - use one of the subtyes!!
/obj/item/deck
	name = "THE DECK OF IMPOSSIBLE AND BROKEN CARDS"
	desc = "You should not be seeing this. If you see this, report it to a developer!!"
	icon = 'icons/roguetown/items/cards/playingcards.dmi'
	icon_state = "deck_full"
	w_class = WEIGHT_CLASS_SMALL
	var/cooldown = 0
	var/list/datum/playingcard/cards = list()
	/// Number of times we will duplicate our deck's contents when created. 2 makes a double sized deck, 3 makes triple sized, etc.
	var/deck_size = 1
	/// How many cards are dealt at a time when our holder deals a hand
	var/hand_size = 5
	/// Icon state used for the backs of the cards this deck provides.
	var/back_icon_state = "singlecard_down"
	grid_width = 32
	grid_height = 32
	possible_item_intents = list(/datum/intent/hand/deal/facedown, /datum/intent/hand/deal/faceup)

/// Returns whether or not the given user is able to access cheating mechanics.
/obj/item/deck/proc/can_user_cheat(mob/living/carbon/human/user)
	return TRUE

/obj/item/deck/proc/get_new_deck()
	PROTECTED_PROC(TRUE)
	SHOULD_CALL_PARENT(TRUE)
	RETURN_TYPE(/list/datum/playingcard)
	return list()

/obj/item/deck/proc/shuffle_deck(mob/user)
	if(cooldown < world.time - 25)
		cards = shuffle(cards)
		playsound(src, 'sound/items/cardshuffle.ogg', 100, TRUE)
		user.visible_message(span_notice("[user] shuffles the deck."), span_notice("I shuffle the deck."), span_notice("I hear the shuffling of cards."))
		cooldown = world.time

/obj/item/deck/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(istype(I, /obj/item/card_hand))
		var/obj/item/card_hand/CH = I
		if(CH.our_deck != src)
			to_chat(user, span_warning("[CH.cards.len > 1 ? "These cards" : "This card"] didn't come from this deck!"))
			return
		cards.Add(CH.cards)
		user.visible_message(span_notice("\The [user] returns \the [CH] to \the [src]."), span_notice("I return \the [CH] to \the [src]."))
		qdel(CH)
		return

/obj/item/deck/AltClick(mob/user)
	. = ..()
	if(.)
		return .
	if(!ishuman(user) || user.stat || !user.canUseTopic(src, BE_CLOSE))
		return
	shuffle_deck(user)
	user.changeNext_move(CLICK_CD_MELEE)

/obj/item/deck/attack_hand(mob/user)
	if(!ishuman(user) || user.stat)
		return
	if(!cards.len)
		to_chat(user, span_warning("It has no cards left to draw."))
		return
	var/mob/living/carbon/human/H = user
	if(H.get_num_arms() <= 0)
		to_chat(user, span_danger("WITH WHAT ARMS?"))
		return
	var/list/datum/playingcard/drawn_cards = list()
	drawn_cards += cards[1]
	var/obj/item/card_hand/C = new(loc.loc, src, drawn_cards)
	if(!user.put_in_hands(C, del_on_fail = TRUE))
		to_chat(user, span_warning("My hands are full!"))
		return
	cards.Cut(1, 2)
	user.visible_message(span_notice("\The [user] draws a card."), span_notice("I draw a card."))
	if(isturf(loc))
		balloon_alert_to_viewers("1 card drawn...")

/obj/item/deck/Initialize(mapload)
	. = ..()
	for(var/i = 0, i < deck_size, i++)
		var/list/datum/playingcard/new_deck = get_new_deck()
		cards.Insert(1, new_deck)
	cards = shuffle(cards)

/obj/item/deck/examine()
	. = ..()
	. += span_notice("It has [cards.len] cards left.")

/obj/item/deck/get_mechanics_examine(mob/user)
	. = ..()
	. += span_smallnotice("I can CLICK-DRAG the deck into my hand slot to pick it up.")
	. += span_smallnotice("I may USE this in my hand to choose whether to shuffle the deck, search it for specific cards to draw, or choose how many cards I wish to deal when dealing a hand.")
	. += span_smallnotice("While holding the deck, I may deal cards with a single CLICK, which throws the card or cards to wherever I am aiming. LEFT CLICK deals a single card. RIGHT CLICK deals a hand of cards instead.")
	. += span_smallnotice("My intents determine whether or not I will deal the cards face-down or face-up.")
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(can_user_cheat(H))
			. += span_smallracialstatinfo("Thanks to Xylix's gifts, I may also CHEAT.")

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
			. += pcard // Make it so.

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


/obj/item/deck/tarot/majorarcana
	name = "tarot deck (major arcana)"

/obj/item/deck/tarot/majorarcana/get_new_deck()
	. = ..()

#undef MAX_HAND_SIZE
#undef TAROT_DECK_DESCRIPTION
