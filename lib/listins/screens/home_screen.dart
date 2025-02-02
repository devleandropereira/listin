import 'package:flutter/material.dart';
import 'package:flutter_listin/_core/helpers/confirmation_dialog.dart';
import 'package:flutter_listin/_core/services/dio_service.dart';
import 'package:flutter_listin/authentication/models/mock_user.dart';
import 'package:flutter_listin/listins/data/database.dart';
import 'package:flutter_listin/listins/screens/widgets/home_drawer.dart';
import 'package:flutter_listin/listins/screens/widgets/home_listin_item.dart';
import '../models/listin.dart';
import 'widgets/listin_add_edit_modal.dart';
import 'widgets/listin_options_modal.dart';

class HomeScreen extends StatefulWidget {
  final MockUser user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Listin> listListins = [];
  late AppDatabase _appDatabase;

  DioService _dioService = DioService();

  @override
  void initState() {
    _appDatabase = AppDatabase();
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    _appDatabase.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HomeDrawer(user: widget.user),
      appBar: AppBar(
        title: const Text("Minhas listas"),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.cloud),
            onSelected: (value) {
              if (value == "SAVE") {
                saveOnServer();
              }
              if (value == "SYNC") {
                syncWithServer();
              }
              if (value == "CLEAR") {
                clearServerData();
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: "SAVE",
                  child: ListTile(
                    leading: Icon(Icons.upload),
                    title: Text("Salvar na nuvem")
                  ),
                ),
                const PopupMenuItem(
                  value: "SYNC",
                  child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text("Sincronizar da nuvem")
                  ),
                ),
                const PopupMenuItem(
                  value: "CLEAR",
                  child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text("Remover dados da nuvem")
                  ),
                )
              ];
            }
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddModal();
        },
        child: const Icon(Icons.add),
      ),
      body: (listListins.isEmpty)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/bag.png"),
                  const SizedBox(height: 32),
                  const Text(
                    "Nenhuma lista ainda.\nVamos criar a primeira?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () {
                return refresh();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                child: ListView(
                  children: List.generate(
                    listListins.length,
                    (index) {
                      Listin listin = listListins[index];
                      return HomeListinItem(
                        listin: listin,
                        showOptionModal: showOptionModal,
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  showAddModal({Listin? listin}) {
    showAddEditListinModal(
      context: context,
      onRefresh: refresh,
      model: listin,
      appDatabase: _appDatabase,
    );
  }

  showOptionModal(Listin listin) {
    showListinOptionsModal(
      context: context,
      listin: listin,
      onRemove: remove,
    ).then((value) {
      if (value != null && value) {
        showAddModal(listin: listin);
      }
    });
  }

  refresh() async {
    // Basta alimentar essa variável com Listins que, quando o método for
    // chamado, a tela sera reconstruída com os itens.
    List<Listin> listaListins = await _appDatabase.getListins();

    setState(() {
      listListins = listaListins;
    });
  }

  void remove(Listin model) async {
    await _appDatabase.deleteListin(int.parse(model.id));
    refresh();
  }

  saveOnServer() async {
    showConfirmationDialog(
        context: context,
        content: "Confirma a sobrescrita dos dados na nuvem?",
      ).then((value) async {
        if (value != null && value) {
          await _dioService.saveLocalToServer(_appDatabase)
              .then((error) => {
                showSnackBar((error != null) ? error : "Salvo com sucesso")
              });
          refresh();
        }
      });
  }

  syncWithServer() async {
    showConfirmationDialog(
      context: context,
      content: "Confirma a sobrescrita dos dados locais?",
    ).then((value) async {
      if (value != null && value) {
        await _dioService.getDataFromServer(_appDatabase);
        refresh();
      }
    });
  }

  clearServerData() async {
    showConfirmationDialog(
      context: context,
      content: "Confirma a remoção dos dados na nuvem?",
    ).then((value) async {
      if (value != null && value) {
        await _dioService.clearServerData()
            .then((value) => showSnackBar("Dados removidos com sucesso"))
            .catchError((error) => showSnackBar(error));
      }
    });
  }

  void showSnackBar(String content) {
    var snackBar = SnackBar(
        content: Text(content),
        action: SnackBarAction(
          label: 'X',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}
