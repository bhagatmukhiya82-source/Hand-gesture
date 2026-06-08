
import cv2
import mediapipe as mp
import webbrowser
import os
import time

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=1, min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_draw = mp.solutions.drawing_utils

# Tip IDs for the 5 fingers
tip_ids = [4, 8, 12, 16, 20]

# Video Capture (0 is usually the default built-in webcam)
cap = cv2.VideoCapture(0)

# Cooldown mechanism to prevent multiple triggers within milliseconds
last_action_time = 0
cooldown_duration = 2  # seconds

print("Hand Gesture Automation System Active... Wave your hand at the camera!")

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        break

    # Flip the frame horizontally for a natural selfie-view mirroring effect
    frame = cv2.flip(frame, 1)
    h, w, c = frame.shape
    
    # Convert image colors to RGB (MediaPipe requires RGB, OpenCV uses BGR)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_frame)

    total_fingers = 0

    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            # Draw the landmark points and connecting lines on the frame
            mp_draw.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)

            # Extract coordinates
            landmarks = hand_landmarks.landmark
            fingers = []

            # 1. Logic for Thumb (Based on horizontal coordinate X)
            # Adjust depending on if it's a left or right hand. This logic assumes a right hand mirrored.
            if landmarks[tip_ids[0]].x > landmarks[tip_ids[0] - 1].x:
                fingers.append(1)
            else:
                fingers.append(0)

            # 2. Logic for 4 Fingers (Based on vertical coordinate Y)
            for i in range(1, 5):
                if landmarks[tip_ids[i]].y < landmarks[tip_ids[i] - 2].y:
                    fingers.append(1)
                else:
                    fingers.append(0)

            total_fingers = fingers.count(1)

            # Handle Automation Triggers (Only execute if cooldown window has passed)
            current_time = time.time()
            if current_time - last_action_time > cooldown_duration:
                
                if total_fingers == 1:
                    print("1 Finger detected -> Opening Claude AI")
                    webbrowser.open("https://claude.ai")
                    last_action_time = current_time

                elif total_fingers == 2:
                    print("2 Fingers detected -> Opening ChatGPT")
                    webbrowser.open("https://chatgpt.com")
                    last_action_time = current_time

                elif total_fingers == 3:
                    print("3 Fingers detected -> Opening Gemini")
                    webbrowser.open("https://gemini.google.com")
                    last_action_time = current_time

                elif total_fingers == 4:
                    print("4 Fingers detected -> Opening LinkedIn")
                    webbrowser.open("https://www.linkedin.com")
                    last_action_time = current_time

                elif total_fingers == 0:
                    # Fist detection (0 fingers)
                    print("Fist detected -> Closing browser tabs")
                    # Command varies by OS. This force closes Chrome. Change to 'msedge' or 'firefox' if needed.
                    if os.name == 'nt':  # For Windows
                        os.system("taskkill /im chrome.exe /f")
                    else:  # For Mac / Linux
                        os.system("pkill -f chrome")
                    last_action_time = current_time

    # UI Overlay: Display the current finger count status on screen
    cv2.putText(frame, f'Fingers: {total_fingers}', (40, 70), 
                cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 3)

    # Show video feed frame
    cv2.imshow("Hand Gesture Controller", frame)

    # Break loop if 'q' key is pressed
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
