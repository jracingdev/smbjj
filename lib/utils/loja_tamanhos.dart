const List<String> tamanhosKimonoInfantil = ['M00', 'M0', 'M1', 'M2', 'M3', 'M4'];
const List<String> tamanhosKimonoAdulto = ['A0', 'A1', 'A2', 'A3', 'A4'];
const List<String> tamanhosKimonoTodos = [...tamanhosKimonoInfantil, ...tamanhosKimonoAdulto];

List<String> tamanhosSugeridosProduto(String categoria) {
  if (categoria == 'kimono') return tamanhosKimonoTodos;
  return const ['PP', 'P', 'M', 'G', 'GG'];
}
