# Tixken

### Onchain tickets that can be minted, verified, used, resold, and reclaimed.

Tixken turns event tickets into onchain assets.

Instead of giving someone a ticket that can simply be screenshotted, Tixken creates a ticket token that can be minted to a specific wallet, verified at the door, burned after entry, and transferred under a host-defined resale cap.

Unused tickets can also be handled according to rules chosen by the event host, either burned or converted into credit.

The goal is simple:

**Create → Mint → Verify → Enter → Resell → Reclaim**

## Demo

🎥 **Demo video:**
https://youtu.be/9_clzTAUY5U

🌐 **Live application:**
https://tixken-elysium.onrender.com/

💻 **Repository:**
https://github.com/mmenyenay/tixken-elysium

---

# Why Tixken?

Traditional event tickets have a few obvious problems.

They can be copied or screenshotted, resale prices can become unreasonable, and an unused ticket normally becomes worthless after the event.

Tixken treats the ticket as an onchain asset instead.

That gives the ticket a verifiable identity and allows its lifecycle to continue beyond simply getting someone through the door.

A ticket can be:

* Created as part of a tokenized event
* Whitelisted to an attendee
* Minted to a wallet
* Verified at the entrance
* Burned after use
* Resold under a host-defined price cap
* Reclaimed after the event according to the host's chosen policy

---

# How it works

## 1. Host creates an event

The host enters the event details, chooses a token symbol, and selects what should happen to tickets that are never used.

The available reclaim policies are:

* Burn unused tickets
* Convert unused tickets into credit

Tixken sends the tokenization request to Brickken's sandbox.

This is a real Brickken API integration, not a simulated token creation.

## 2. Attendee receives a ticket

The attendee provides the event ID, wallet address, and email.

Tixken handles the Brickken whitelist and mint flow.

The resulting ticket contains a QR code connected to the specific ticket token.

## 3. Ticket is verified at the door

The attendee presents the ticket at the entrance.

Tixken checks the ticket and burns the token after successful entry.

This prevents the same ticket from being used again.

A successful Sepolia burn transaction is included in the verification section below.

## 4. Ticket resale

If an attendee cannot attend the event, the ticket can be listed for resale.

The host defines the maximum resale price.

The seller signs the transfer with their own wallet, and the ticket is transferred directly to the buyer.

Tixken does not take custody of the ticket.

## 5. Agentic reclaim

Tixken also includes an agentic reclaim system.

The reclaim agent has an onchain identity registered through Brickken's Agentic API.

The host's selected reclaim policy determines whether an unused ticket should be burned or converted into credit.

The RAMS mandate is configured with scoped actions for these operations.

The mandate setup is confirmed onchain. Final end-to-end delegated execution testing is still being completed, so this README does not claim that the full autonomous RAMS execution is already proven live.

--


---

