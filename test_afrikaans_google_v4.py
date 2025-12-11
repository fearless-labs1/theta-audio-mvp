#!/usr/bin/env python3
"""
THETA AFRIKAANS - 3 GEBED TOETS (KORREK)
═══════════════════════════════════════════════════════════════════════════════

Korrekte Theta klankstruktuur (pas by Engels):
Piano Bell → 2s pouse → "Hemelse Vader" → 2s pouse → Gebed

Instellings aangepas om by Engels kwaliteit te pas:
- piano_bell.mp3 (nie generiese beep nie)
- Spreekspoed: 0.75 (stadiger, pas by Engels se 0.70)
- trim_silence() vir konsekwente pouses
"""

import os
import io
from google.cloud import texttospeech
from pydub import AudioSegment
from pydub.silence import detect_leading_silence

OUTPUT_DIR = "test_afrikaans_google"

# Google Cloud TTS instellings (aangepas vir beter kwaliteit)
VOICE_NAME = "af-ZA-Standard-A"
SPEAKING_RATE = 0.75  # Stadiger - pas by Engels se 0.70
PITCH = -2.0  # Meek effek

# Pouse tydsberekening
PAUSE_DURATION_MS = 2000  # 2 sekondes

# Piano bell lêer pad
PIANO_BELL_PATH = r"C:\Users\dusty\Documents\theta_audio_mvp_android\piano_bell.mp3"

TEST_PRAYERS = [
    (
        "test_01_oggend",
        "Mag ek hierdie dag met vars energie ontwaak. Ek wy my gedagtes en dade aan God se wil toe. Laat my hart gevul wees met dankbaarheid vir 'n nuwe begin. Ek kies om in liefde en lig te wandel. Hierdie dag is 'n geskenk van genade. Amen."
    ),
    (
        "test_02_middag",
        "Ons Vader wat in die hemele is, laat U Naam geheilig word. Laat U koninkryk kom. Laat U wil geskied, soos in die hemel net so ook op die aarde. Gee ons vandag ons daaglikse brood. En vergewe ons ons skulde, soos ons ook ons skuldenaars vergewe. En lei ons nie in versoeking nie, maar verlos ons van die Bose. Amen."
    ),
    (
        "test_03_goliat",
        "Ek breek elke ketting wat my bind. Elke vesting van die vyand word afgebreek. Elke juk word vernietig. Deur die krag van Christus is ek vry. Geen wapen gevorm teen my sal slaag nie. Ek wandel in totale vryheid. Amen."
    ),
]

def trim_silence(audio_segment, silence_thresh=-50):
    """
    Verwyder stilte aan die begin en einde van klank.
    SLEUTEL tot konsekwente pouse tydsberekening!
    """
    start_trim = detect_leading_silence(audio_segment, silence_threshold=silence_thresh)
    end_trim = detect_leading_silence(audio_segment.reverse(), silence_threshold=silence_thresh)
    duration = len(audio_segment)
    trimmed = audio_segment[start_trim:duration-end_trim]
    return trimmed

def apply_meek_effect(audio_segment):
    """Sagter, meer nederige klank."""
    softer = audio_segment - 2
    return softer.fade_in(100).fade_out(100)

def generate_tts_audio(text, client):
    """Genereer TTS klank en return AudioSegment."""
    voice = texttospeech.VoiceSelectionParams(
        language_code="af-ZA",
        name=VOICE_NAME,
    )
    
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3,
        speaking_rate=SPEAKING_RATE,
        pitch=PITCH,
    )
    
    synthesis_input = texttospeech.SynthesisInput(text=text)
    
    response = client.synthesize_speech(
        input=synthesis_input,
        voice=voice,
        audio_config=audio_config
    )
    
    return AudioSegment.from_mp3(io.BytesIO(response.audio_content))

def load_piano_bell():
    """Laai die piano_bell.mp3 lêer."""
    if os.path.exists(PIANO_BELL_PATH):
        print(f"   ✅ Piano bell gelaai: {PIANO_BELL_PATH}")
        bell = AudioSegment.from_mp3(PIANO_BELL_PATH)
        return trim_silence(bell)
    else:
        print(f"   ❌ Piano bell nie gevind nie: {PIANO_BELL_PATH}")
        print("   Maak seker die lêer bestaan!")
        return None

def generate_complete_prayer(prayer_text, filename, client, piano_bell, hemelse_vader):
    """
    Genereer volledige gebed met:
    Piano Bell → 2s → "Hemelse Vader" → 2s → Gebed
    """
    try:
        print(f"🎙️  Genereer {filename}.mp3...")
        
        # 1. Genereer gebed TTS
        prayer_audio = generate_tts_audio(prayer_text, client)
        
        # 2. Trim stilte van gebed
        prayer_trimmed = trim_silence(prayer_audio)
        prayer_processed = apply_meek_effect(prayer_trimmed)
        
        # 3. Skep 2 sekonde stilte
        pause = AudioSegment.silent(duration=PAUSE_DURATION_MS)
        
        # 4. Bou volledige klank:
        # Piano Bell → 2s → "Hemelse Vader" → 2s → Gebed
        complete = piano_bell + pause + hemelse_vader + pause + prayer_processed
        
        # 5. Stoor
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        filepath = os.path.join(OUTPUT_DIR, f"{filename}.mp3")
        complete.export(filepath, format="mp3", bitrate="192k")  # Hoër kwaliteit
        
        duration_sec = len(complete) / 1000
        print(f"✅ Gegenereer: {filename}.mp3 ({duration_sec:.1f} sekondes)")
        return True
        
    except Exception as e:
        print(f"❌ Fout met {filename}: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("═" * 60)
    print("THETA AFRIKAANS - 3 GEBED TOETS (KORREK)")
    print("═" * 60)
    print(f"Stem: {VOICE_NAME}")
    print(f"Spreekspoed: {SPEAKING_RATE} (stadiger, pas by Engels)")
    print(f"Struktuur: Piano Bell → 2s → Hemelse Vader → 2s → Gebed")
    print("═" * 60)
    
    try:
        client = texttospeech.TextToSpeechClient()
        print("✅ Google Cloud TTS API verbind\n")
    except Exception as e:
        print(f"❌ Kon nie verbind nie: {e}")
        return
    
    # 1. Laai piano bell
    print("📢 Voorbereiding...")
    piano_bell = load_piano_bell()
    if piano_bell is None:
        return
    print(f"   Piano bell duur: {len(piano_bell)}ms")
    
    # 2. Genereer "Hemelse Vader" inleiding
    print("   Genereer 'Hemelse Vader' inleiding...")
    hv_audio = generate_tts_audio("Hemelse Vader.", client)
    hv_trimmed = trim_silence(hv_audio)
    hv_processed = apply_meek_effect(hv_trimmed)
    print(f"   Hemelse Vader duur: {len(hv_processed)}ms")
    
    # 3. Genereer toets gebede
    print("\n🙏 Genereer gebede...")
    success_count = 0
    
    for filename, text in TEST_PRAYERS:
        if generate_complete_prayer(text, filename, client, piano_bell, hv_processed):
            success_count += 1
    
    print("\n" + "═" * 60)
    print("TOETS VOLTOOI")
    print("═" * 60)
    print(f"✅ {success_count}/3 gebede gegenereer")
    print(f"\n📁 Luister: explorer {OUTPUT_DIR}")
    print("\nElke gebed het:")
    print("   🎹 Piano Bell")
    print("   ⏸️  2 sekonde pouse")
    print("   🗣️  'Hemelse Vader'")
    print("   ⏸️  2 sekonde pouse")
    print("   🙏 Gebed (0.75 spoed)")
    print("═" * 60)

if __name__ == "__main__":
    if not os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
        print("❌ FOUT: GOOGLE_APPLICATION_CREDENTIALS nie gestel nie")
        exit(1)
    main()
