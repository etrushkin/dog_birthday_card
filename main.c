/* Eugene Trushkin 2021
 *
 * Quick and dirty code for a dog-like birthday card. It plays Happy bithday song and 
 * swings it's tail.
 *
 * Tail base has a hinge. The tail's actuator is a small phone speaker, which membrane is
 * glued to the tail near to the hinge. The base of the speaker is glued to the card.
 * Tail speaker is connected to pins 0 and 2, which allows movement in both directions by
 * alternating voltage.
 * 
 * It makes sound with a small piezo busser.
 * 
 * This program uses code from David Johnson-Davies, see:
 * http://www.technoblogy.com/show?20MO
 */

#include <avr/io.h>
#include <avr/eeprom.h>
#include <avr/interrupt.h>
#define F_CPU 1000000UL
#include <util/delay.h>
#include <stdint.h>
#include <stddef.h>

#define  PIN_SOUND 1  // Can be 1 or 4
#define  PIN_TAIL1 0
#define  PIN_TAIL2 2
#define  MAX_COUNT 1000 // Tail winging period

// http://www.technoblogy.com/show?20MO
// Cater for 16MHz, 8MHz, or 1MHz clock:
static const int clock = ((F_CPU/1000000UL) == 16) ? 4 : ((F_CPU/1000000UL) == 8) ? 3 : 0;
static const uint8_t scale[] = {239,226,213,201,190,179,169,160,151,142,134,127};


static const uint8_t notes[] = {
3, 3, 5, 3, 8, 7, 0,
3, 3, 5, 3, 10, 8, 0,
3, 3, 3, 12, 8, 7, 5, 0,
1, 1, 12, 8, 10, 8, 0,
};
static const uint8_t octaves[] = {
4, 4, 4, 4, 4, 4, 0,
4, 4, 4, 4, 4, 4, 0,
4, 5, 4, 4, 4, 4, 4, 0,
5, 5, 4, 4, 4, 4, 0,
};
static const uint8_t durations[] = {
8, 8, 4, 4, 4, 2, 1,
8, 8, 4, 4, 4, 2, 1,
8, 8, 4, 4, 4, 4, 4, 1,
8, 8, 4, 4, 4, 2, 1,
};

static const uint16_t tempo = 100;

static void note (int n, int octave);

int main (void)
{
  // Tail timer initialisation
  TIMSK = 1<<TOIE0;
  TCCR0B = (1<<CS00 || 1<<CS02);
  DDRB = DDRB | (1<<PIN_TAIL1 | 1<<PIN_TAIL2);
  sei();
  
  // Playing music
  while(1)
  {
    for (int i=0; i < sizeof(notes)/sizeof(uint8_t); i++)
    {
      note(notes[i], octaves[i]);
      for(int j=0; j<durations[i]; j++)
      {
        _delay_ms(tempo);
      }
      note(0, 0);
      _delay_ms(50);
    }
  }
  return 0;
}


// http://www.technoblogy.com/show?20MO
static void note (int n, int octave)
{
  int prescaler = 8 + clock - (octave + n/12);
  if (prescaler<1 || prescaler>15 || octave==0)
  {
    prescaler = 0;
  }
  DDRB = (DDRB & ~(1<<PIN_SOUND)) | (prescaler != 0) << PIN_SOUND;
  OCR1C = scale[n % 12] - 1;
  GTCCR = (PIN_SOUND == 4)<<COM1B0;
  TCCR1 = 1<<CTC1 | (PIN_SOUND == 1)<<COM1A0 | prescaler<<CS10;
}


// Dog tail movements
ISR (TIMER0_OVF_vect)
{
  static uint16_t count = 0;
  static uint8_t state = 0;

  if(count > MAX_COUNT)
  {
    if(state)
    {
      PORTB =  1<<PIN_TAIL2 | (PORTB & ~(1<<PIN_TAIL1));
    }
    else
    {
      PORTB = 1<<PIN_TAIL1 | (PORTB & ~(1<<PIN_TAIL2));
    }
    count = 0;
    state = (!state);
  }
  else
  {
    count++;
  }
	sei();
}
