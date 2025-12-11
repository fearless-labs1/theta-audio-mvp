#!/usr/bin/env python3
"""
THETA AFRIKAANS - 3 GEBED TOETS (GOOGLE CLOUD TTS) - FIXED
"""

import os
import io
from google.cloud import texttospeech
from pydub import AudioSegment
from pydub.silence import detect_leading_silence

OUTPUT_DIR = "test_afrikaans_google"

# FIXED: Correct Afrikaans voice name
VOICE_NAME = "af-ZA-Standard-A"  # Standard Afrikaans female voice
SPEAKING_RATE = 0.85
PITCH = -2.0

TEST_PRAYERS = [
    (
        "test_01_oggend",
        "Hemelse Vader. Mag ek hierdie dag met vars energie ontwaak. Ek wy my gedagtes en dade aan God se wil toe. Laat my hart gevul wees met dankbaarheid vir 'n nuwe begin. Ek kies om in liefde en lig te wandel. Hierdie dag is 'n geskenk van genade. Amen."
    ),
    (
        "test_02_middag",
        "Hemelse Vader. Ons Vader wat in die hemele is, laat U Naam geheilig word. Laat U koninkryk kom. Laat U wil geskied, soos in die hemel net so ook op die aarde. Gee ons vandag ons daaglikse brood. En vergewe ons ons skulde, soos ons ook ons skuldenaars vergewe. En lei ons nie in versoeking nie, maar verlos ons van die Bose. Amen."
    ),
    (
        "test_03_goliat",
        "Hemelse Vader. Ek breek elke ketting wat my bind. Elke vesting van die vyand word afgebreek. Elke juk word vernietig. Deur die krag van Christus is ek vry. Geen wapen gevorm teen my sal slaag nie. Ek wandel in totale vryheid. Amen."
    ),
]

def trim_silence(audio_segment, silence_thresh=-50):
    start_trim = detect_leading_silence(audio_segment, silence_threshold=silence_thresh)
    end_trim = detect_leading_silence(audio_segment.reverse(), silence_threshold=silence_thresh)
    duration = len(audio_segment)
    return audio_segment[start_trim:duration-end_trim]

def apply_meek_effect(audio_segment):
    softer = audio_segment - 2
    return softer.fade_in(100).fade_out(100)

def generate_test_prayer(prayer_text, filename, client):
    try:
        print(f"🎙️  Genereer {filename}.mp3...")
        
        voice = texttospeech.VoiceSelectionParams(
            language_code="af-ZA",
            name=VOICE_NAME,
        )
        
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=SPEAKING_RATE,
            pitch=PITCH,
        )
        
        synthesis_input = texttospeech.SynthesisInput(text=prayer_text)
        
        response = client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config
        )
        
        audio = AudioSegment.from_mp3(io.BytesIO(response.audio_content))
        trimmed = trim_silence(audio)
        processed = apply_meek_effect(trimmed)
        
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        filepath = os.path.join(OUTPUT_DIR, f"{filename}.mp3")
        processed.export(filepath, format="mp3", bitrate="128k")
        
        duration_sec = len(processed) / 1000
        print(f"✅ Gegenereer: {filename}.mp3 ({duration_sec:.1f} sekondes)")
        return True
        
    except Exception as e:
        print(f"❌ Fout met {filename}: {e}")
        return False

def list_afrikaans_voices(client):
    """List all available Afrikaans voices"""
    print("\n📋 Beskikbare Afrikaanse stemme:")
    print("-" * 40)
    voices = client.list_voices(language_code="af-ZA")
    for voice in voices.voices:
        print(f"   {voice.name} ({voice.ssml_gender.name})")
    print("-" * 40)

def main():
    print("═" * 60)
    print("THETA AFRIKAANS - 3 GEBED TOETS (GOOGLE CLOUD TTS)")
    print("═" * 60)
    print(f"Stem: {VOICE_NAME}")
    print(f"Spreekspoed: {SPEAKING_RATE}")
    print(f"Toonhoogte: {PITCH}")
    print(f"Uitvoer: {OUTPUT_DIR}/")
    print("═" * 60)
    
    try:
        client = texttospeech.TextToSpeechClient()
        print("✅ Google Cloud TTS API verbind")
        
        # Show available voices
        list_afrikaans_voices(client)
        
    except Exception as e:
        print(f"❌ Kon nie met Google Cloud verbind nie: {e}")
        return
    
    success_count = 0
    
    for filename, text in TEST_PRAYERS:
        if generate_test_prayer(text, filename, client):
            success_count += 1
    
    print("\n" + "═" * 60)
    print("TOETS VOLTOOI")
    print("═" * 60)
    print(f"✅ {success_count}/3 gebede gegenereer")
    print(f"\n📁 Luister na die lêers in: {OUTPUT_DIR}/")
    print("═" * 60)

if __name__ == "__main__":
    if not os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
        print("❌ FOUT: GOOGLE_APPLICATION_CREDENTIALS nie gestel nie")
        exit(1)
    main()
