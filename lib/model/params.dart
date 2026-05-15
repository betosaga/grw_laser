
class Params {
  String url;
  int pinGas;
  int pinLaser;
  int pinMassa;
  int variazioneZStart;
  int variazioneZC;
  int variazioneZEnd;
  int stepCordoni;
  int maxCordoni;
  int velocitaSaldatura;
  int accelerazioneSaldatura;
  int velocita;
  int cordoneIniziale;

  Params({
    this.url = '',
    this.pinGas = 3,
    this.pinLaser = 1,
    this.pinMassa = 4,
    this.variazioneZStart = 14,
    this.variazioneZC = 14,
    this.variazioneZEnd = 14,
    this.stepCordoni = 2,
    this.maxCordoni = 0,
    this.velocitaSaldatura = 20,
    this.accelerazioneSaldatura = 100,
    this.velocita = 100,
    this.cordoneIniziale = 1,
  });
}