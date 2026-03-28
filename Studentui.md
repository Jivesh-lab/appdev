# 📱 ClassPulse - Student UI Implementation Guide

## 🎯 Objective
Build the **Student Response UI** for ClassPulse using Flutter.

This UI should:
- Allow students to select their understanding level
- Track current and previous selection
- Be independent of backend (use local state only)
- Follow the given theme and color palette

---

## 🎨 Theme Guidelines

### Colors:
- Primary Navy: `#3C486B`
- Background: `#F4F7FE`
- Card: White
- Got It: `#E1F5FE`
- Sort Of: `#FFF3E0`
- Lost: `#FFEBEE`

### UI Rules:
- Rounded corners (radius: 24)
- Large tap-friendly buttons
- Clean spacing and minimal layout

---

## 🧩 Screen: Student Response Screen

### Layout:
- AppBar with title "ClassPulse"
- Heading text:
  - "How well did you understand?"
- 3 large selectable cards:
  - Got it
  - Sort of
  - Lost

---

## 🧠 State Management (Local Only)

Maintain:

selectedType: String?
previousType: String?


---

## 🔄 Behavior

### On Card Tap:
- Update:
  - `previousType = selectedType`
  - `selectedType = newType`
- Show Snackbar: "Response updated"
- Print data to console (temporary backend simulation)

---

## 📊 Schema Mapping (for future backend)


StudentResponse {
user_id: string,
session_id: string,
type: string,
previous_type: string | null,
joined_at: timestamp,
updated_at: timestamp
}


Map UI:
- `type` → selectedType
- `previous_type` → previousType

---

## 🧱 Components to Build

### 1. StudentResponseScreen (StatefulWidget)
Contains:
- Title
- 3 response cards
- State logic

---

### 2. ResponseCard (Reusable Widget)

Props:
- title (String)
- color (Color)
- icon (IconData)
- isSelected (bool)
- onTap (function)

---

## 🎨 Response Card Design

Each card should:
- Have background color based on type
- Rounded corners (24 radius)
- Padding inside
- Icon + Text horizontally aligned
- Highlight when selected:
  - Add border or darker shade

---

## 📦 Card Variants

### Got It
- Color: Light Blue
- Icon: check_circle
- Value: "got_it"

---

### Sort Of
- Color: Light Orange
- Icon: remove_circle_outline
- Value: "sort_of"

---

### Lost
- Color: Light Red
- Icon: cancel
- Value: "lost"

---

## 🔔 Feedback

After selection:
- Show Snackbar: "Response updated"

---

## 🧪 Temporary Logic

Use:

print({
"type": selectedType,
"previous_type": previousType,
"updated_at": DateTime.now()
});


---

## 📁 Suggested File Structure


lib/
screens/
student_response_screen.dart

widgets/
response_card.dart


---

## 🚀 Expected Outcome

- Clean UI screen
- Smooth selection interaction
- Visual feedback on selection
- Ready to integrate backend later

---

## ⚠️ Notes

- Do NOT connect Firebase yet
- Focus only on UI + state
- Keep code modular and reusable

---