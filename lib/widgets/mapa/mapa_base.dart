import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../config/constantes.dart';
import 'marcador_mapa.dart';

/// Mapa com marcadores, que se enquadra automaticamente para mostrar todos.
class MapaBase extends StatefulWidget {
  final List<MarcadorMapa> marcadores;

  const MapaBase({super.key, required this.marcadores});

  @override
  State<MapaBase> createState() => _MapaBaseState();
}

class _MapaBaseState extends State<MapaBase> {
  final _controller = MapController();
  bool _pronto = false;

  CameraFit? _enquadramento() {
    if (widget.marcadores.isEmpty) return null;
    return CameraFit.coordinates(
      coordinates: widget.marcadores.map((m) => m.ponto).toList(),
      padding: EdgeInsets.all(60),
      maxZoom: 17,
    );
  }

  void centralizar() {
    final fit = _enquadramento();
    if (fit != null) {
      _controller.fitCamera(fit);
    } else {
      _controller.move(centroPadrao, zoomPadrao);
    }
  }

  @override
  void didUpdateWidget(MapaBase antigo) {
    super.didUpdateWidget(antigo);
    // Quando entra ou sai um chamado, reenquadra o mapa
    if (_pronto && antigo.marcadores.length != widget.marcadores.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => centralizar());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _pino(MarcadorMapa m) {
    final pino = Container(
      decoration: BoxDecoration(
        color: m.cor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: m.tamanho >= 44 ? 3 : 2),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6)],
      ),
      child: Icon(m.icone, color: Colors.white, size: m.tamanho / 2),
    );

    return MouseRegion(
      cursor: m.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: m.onTap,
        child: m.rotulo != null ? Tooltip(message: m.rotulo!, child: pino) : pino,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: centroPadrao,
              initialZoom: zoomPadrao,
              initialCameraFit: _enquadramento(),
              onMapReady: () => _pronto = true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.seguranca_app',
              ),
              MarkerLayer(
                markers: [
                  for (final m in widget.marcadores)
                    Marker(
                      point: m.ponto,
                      width: m.tamanho,
                      height: m.tamanho,
                      child: _pino(m),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: "Centralizar",
              onPressed: centralizar,
              child: Icon(Icons.center_focus_strong),
            ),
          ),
        ],
      ),
    );
  }
}
