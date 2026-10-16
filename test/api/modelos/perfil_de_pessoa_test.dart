import 'package:connactions_app/api/modelos/perfil_de_pessoa.dart';
import 'package:flutter_test/flutter_test.dart';

// Os três contadores com valores diferentes entre si: um contador trocado não fecha por acaso.
Map<String, dynamic> perfilJson({Object? atividades = 23}) => {
  'id': 'p1',
  'handle': 'bia',
  'nome': 'Bia Souza',
  'foto_url': 'http://midia.local/midia/perfis/bia.jpg',
  'bio': 'Trilha aos domingos',
  'contadores': {'turmas': 4, 'atividades': atividades, 'conexoes': 18},
};

void main() {
  test(
    'PerfilDePessoa.deJson lê a cara pública, a bio e os três contadores',
    () {
      final p = PerfilDePessoa.deJson(perfilJson());
      expect(p.id, 'p1');
      expect(p.handle, 'bia');
      expect(p.nome, 'Bia Souza');
      expect(p.fotoUrl, endsWith('perfis/bia.jpg'));
      expect(p.bio, 'Trilha aos domingos');
      expect(p.turmas, 4);
      expect(p.atividades, 23);
      expect(p.conexoes, 18);
    },
  );

  test('atividades vem nulo quando a pessoa as deixou só para si', () {
    final p = PerfilDePessoa.deJson(perfilJson(atividades: null));
    expect(p.atividades, isNull);
    expect(p.turmas, 4);
    expect(p.conexoes, 18);
  });

  test('pessoa é a cara pública, para o avatar e a lista', () {
    final p = PerfilDePessoa.deJson(perfilJson());
    expect(p.pessoa.id, 'p1');
    expect(p.pessoa.handle, 'bia');
    expect(p.pessoa.nome, 'Bia Souza');
    expect(p.pessoa.fotoUrl, endsWith('perfis/bia.jpg'));
    expect(p.pessoa.primeiroNome, 'Bia');

    final semFoto = PerfilDePessoa.deJson({...perfilJson(), 'foto_url': null});
    expect(semFoto.pessoa.fotoUrl, isNull);
  });
}
