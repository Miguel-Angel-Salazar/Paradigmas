// Sistema de análisis y control de producción industrial
// Programación funcional en Java

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.function.BiConsumer;
import java.util.function.BiFunction;
import java.util.function.BiPredicate;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.function.Supplier;
import java.util.function.UnaryOperator;
import java.util.stream.Collectors;


class RegistroProducto {

    private int codigoProducto;
    private String nombreProducto;
    private String lineaProduccion;
    private int cantidadProducto;
    private int cantidadDefectuosa;
    private double costoUnitario;
    private int minutosUtilizados;
    private double kgMateriaPrima;
    private int metaProduccion;

    public RegistroProducto(
            int codigoProducto,
            String nombreProducto,
            String lineaProduccion,
            int cantidadProducto,
            int cantidadDefectuosa,
            double costoUnitario,
            int minutosUtilizados,
            double kgMateriaPrima,
            int metaProduccion) {

        this.codigoProducto = codigoProducto;
        this.nombreProducto = nombreProducto;
        this.lineaProduccion = lineaProduccion;
        this.cantidadProducto = cantidadProducto;
        this.cantidadDefectuosa = cantidadDefectuosa;
        this.costoUnitario = costoUnitario;
        this.minutosUtilizados = minutosUtilizados;
        this.kgMateriaPrima = kgMateriaPrima;
        this.metaProduccion = metaProduccion;
    }

    public int getCodigoProducto() {
        return codigoProducto;
    }

    public String getNombreProducto() {
        return nombreProducto;
    }

    public String getLineaProduccion() {
        return lineaProduccion;
    }

    public int getCantidadProducto() {
        return cantidadProducto;
    }

    public int getCantidadDefectuosa() {
        return cantidadDefectuosa;
    }

    public double getCostoUnitario() {
        return costoUnitario;
    }

    public int getMinutosUtilizados() {
        return minutosUtilizados;
    }

    public double getKgMateriaPrima() {
        return kgMateriaPrima;
    }

    public int getMetaProduccion() {
        return metaProduccion;
    }

    public void setCantidadProducto(int cantidadProducto) {
        this.cantidadProducto = cantidadProducto;
    }

    @Override
    public String toString() {
        return "RegistroProducto{" +
                "codigoProducto=" + codigoProducto +
                ", nombreProducto='" + nombreProducto + '\'' +
                ", lineaProduccion='" + lineaProduccion + '\'' +
                ", cantidadProducto=" + cantidadProducto +
                ", cantidadDefectuosa=" + cantidadDefectuosa +
                ", costoUnitario=" + costoUnitario +
                ", minutosUtilizados=" + minutosUtilizados +
                ", kgMateriaPrima=" + kgMateriaPrima +
                ", metaProduccion=" + metaProduccion +
                '}';
    }
}


public class ejercicio_trabajo_java{

    public static void main(String[] args) throws Exception {

        // =========================================================
        // 1. CREAR REGISTROS DE PRODUCCIÓN
        // =========================================================

        List<RegistroProducto> registros = new ArrayList<>(Arrays.asList(

                new RegistroProducto(
                        101,
                        "Disco de freno",
                        "Linea A",
                        950,
                        35,
                        85.50,
                        480,
                        120.5,
                        1000
                ),

                new RegistroProducto(
                        102,
                        "Pastilla de freno",
                        "Linea A",
                        1200,
                        20,
                        42.75,
                        450,
                        95.2,
                        1100
                ),

                new RegistroProducto(
                        103,
                        "Biela",
                        "Linea B",
                        780,
                        65,
                        120.00,
                        510,
                        180.4,
                        900
                ),

                new RegistroProducto(
                        104,
                        "Piston",
                        "Linea B",
                        1400,
                        25,
                        75.30,
                        500,
                        160.8,
                        1300
                ),

                new RegistroProducto(
                        105,
                        "Cigueñal",
                        "Linea C",
                        600,
                        70,
                        250.00,
                        600,
                        300.5,
                        750
                ),

                new RegistroProducto(
                        106,
                        "Arbol de levas",
                        "Linea C",
                        900,
                        30,
                        180.00,
                        550,
                        220.3,
                        850
                )
        ));


        // =========================================================
        // 2. SUPPLIER
        // Generar automáticamente un registro de prueba
        // =========================================================

        Supplier<RegistroProducto> proveedorRegistro =
                () -> new RegistroProducto(
                        107,
                        "Bomba de aceite",
                        "Linea D",
                        1000,
                        15,
                        95.00,
                        490,
                        130.0,
                        950
                );

        RegistroProducto nuevoRegistro = proveedorRegistro.get();

        registros.add(nuevoRegistro);

        System.out.println("REGISTRO GENERADO AUTOMÁTICAMENTE:");
        System.out.println(nuevoRegistro);


        // =========================================================
        // 3. PREDICATE
        // Identificar productos críticos
        //
        // Se considera crítico un producto que tenga más del
        // 5% de unidades defectuosas.
        // =========================================================

        Predicate<RegistroProducto> productoCritico =
                registro -> {

                    if (registro.getCantidadProducto() == 0) {
                        return false;
                    }

                    double porcentajeDefectos =
                            (registro.getCantidadDefectuosa() * 100.0)
                                    / registro.getCantidadProducto();

                    return porcentajeDefectos > 5;
                };

        List<RegistroProducto> productosCriticos =
                registros.stream()
                        .filter(productoCritico)
                        .collect(Collectors.toList());

        System.out.println("\nPRODUCTOS CRÍTICOS:");

        productosCriticos.forEach(registro -> {

            double porcentaje =
                    (registro.getCantidadDefectuosa() * 100.0)
                            / registro.getCantidadProducto();

            System.out.printf(
                    "%s - %.2f%% de defectos%n",
                    registro.getNombreProducto(),
                    porcentaje
            );
        });


        // =========================================================
        // 4. PREDICATE
        // Productos que superaron la meta
        // =========================================================

        Predicate<RegistroProducto> superoMeta =
                registro ->
                        registro.getCantidadProducto()
                                > registro.getMetaProduccion();

        List<RegistroProducto> productosSobreMeta =
                registros.stream()
                        .filter(superoMeta)
                        .collect(Collectors.toList());

        System.out.println("\nPRODUCTOS QUE SUPERARON LA META:");

        productosSobreMeta.forEach(registro ->
                System.out.println(
                        registro.getNombreProducto()
                                + " - Producción: "
                                + registro.getCantidadProducto()
                                + " - Meta: "
                                + registro.getMetaProduccion()
                )
        );


        // =========================================================
        // 5. FILTRAR POR LÍNEA DE PRODUCCIÓN
        // =========================================================

        Predicate<RegistroProducto> perteneceLineaA =
                registro ->
                        registro.getLineaProduccion()
                                .equalsIgnoreCase("Linea A");

        List<RegistroProducto> productosLineaA =
                registros.stream()
                        .filter(perteneceLineaA)
                        .collect(Collectors.toList());

        System.out.println("\nPRODUCTOS DE LA LINEA A:");

        productosLineaA.forEach(registro ->
                System.out.println(
                        registro.getNombreProducto()
                )
        );


        // =========================================================
        // 6. FUNCTION
        // Calcular porcentaje de cumplimiento de la meta
        // =========================================================

        Function<RegistroProducto, Double> calcularCumplimiento =
                registro -> {

                    if (registro.getMetaProduccion() == 0) {
                        return 0.0;
                    }

                    return registro.getCantidadProducto()
                            * 100.0
                            / registro.getMetaProduccion();
                };

        System.out.println("\nCUMPLIMIENTO DE CADA PRODUCTO:");

        registros.stream()
                .forEach(registro ->
                        System.out.printf(
                                "%s - %.2f%%%n",
                                registro.getNombreProducto(),
                                calcularCumplimiento.apply(registro)
                        )
                );


        // =========================================================
        // 7. FUNCTION
        // Calcular costo total de fabricación de cada registro
        // =========================================================

        Function<RegistroProducto, Double> calcularCostoTotal =
                registro ->
                        registro.getCantidadProducto()
                                * registro.getCostoUnitario();

        System.out.println("\nCOSTO DE FABRICACIÓN POR PRODUCTO:");

        registros.stream()
                .forEach(registro ->
                        System.out.printf(
                                "%s - $%,.2f%n",
                                registro.getNombreProducto(),
                                calcularCostoTotal.apply(registro)
                        )
                );


        // =========================================================
        // 8. BIFUNCTION
        // Calcular pérdida económica por defectuosos
        // =========================================================

        BiFunction<Integer, Double, Double> calcularPerdida =
                (cantidadDefectuosa, costoUnitario) ->
                        cantidadDefectuosa * costoUnitario;

        System.out.println("\nPÉRDIDA POR PRODUCTOS DEFECTUOSOS:");

        registros.stream()
                .forEach(registro -> {

                    double perdida =
                            calcularPerdida.apply(
                                    registro.getCantidadDefectuosa(),
                                    registro.getCostoUnitario()
                            );

                    System.out.printf(
                            "%s - $%,.2f%n",
                            registro.getNombreProducto(),
                            perdida
                    );
                });


        // =========================================================
        // 9. CONSUMER
        // Agregar unidades adicionales a un registro
        // =========================================================

        Consumer<RegistroProducto> agregarUnidades =
                registro ->
                        registro.setCantidadProducto(
                                registro.getCantidadProducto() + 100
                        );

        RegistroProducto registroModificar =
                registros.stream()
                        .filter(registro ->
                                registro.getCodigoProducto() == 101)
                        .findFirst()
                        .orElse(null);

        if (registroModificar != null) {

            System.out.println(
                    "\nCANTIDAD ANTES DE AGREGAR UNIDADES:"
            );

            System.out.println(
                    registroModificar.getCantidadProducto()
            );

            agregarUnidades.accept(registroModificar);

            System.out.println(
                    "CANTIDAD DESPUÉS DE AGREGAR 100 UNIDADES:"
            );

            System.out.println(
                    registroModificar.getCantidadProducto()
            );
        }


        // =========================================================
        // 10. UNARYOPERATOR
        // Aplicar un aumento porcentual a la producción
        // =========================================================

        UnaryOperator<Integer> aumentarCincoPorCiento =
                cantidad ->
                        (int) (cantidad * 1.05);

        RegistroProducto registroAjustar =
                registros.stream()
                        .filter(registro ->
                                registro.getCodigoProducto() == 104)
                        .findFirst()
                        .orElse(null);

        if (registroAjustar != null) {

            int cantidadAnterior =
                    registroAjustar.getCantidadProducto();

            int cantidadNueva =
                    aumentarCincoPorCiento.apply(cantidadAnterior);

            registroAjustar.setCantidadProducto(cantidadNueva);

            System.out.println(
                    "\nAJUSTE DEL 5% EN EL PRODUCTO 104:"
            );

            System.out.println(
                    "Cantidad anterior: " + cantidadAnterior
            );

            System.out.println(
                    "Cantidad nueva: " + cantidadNueva
            );
        }


        // =========================================================
        // 11. BIPREDICATE
        // Validar si un producto cumple dos condiciones
        //
        // En este caso:
        // - Cumplir o superar la meta
        // - Tener menos del 5% de defectos
        // =========================================================

        BiPredicate<RegistroProducto, Double> aplicaBeneficio =
                (registro, porcentajeMaximoDefectos) -> {

                    double porcentajeDefectos =
                            (registro.getCantidadDefectuosa() * 100.0)
                                    / registro.getCantidadProducto();

                    return registro.getCantidadProducto()
                                >= registro.getMetaProduccion()
                            && porcentajeDefectos
                                < porcentajeMaximoDefectos;
                };

        RegistroProducto empleadoProduccion =
                registros.get(1);

        boolean aplica =
                aplicaBeneficio.test(
                        empleadoProduccion,
                        5.0
                );

        System.out.println(
                "\nVALIDACIÓN DE BENEFICIO:"
        );

        System.out.println(
                empleadoProduccion.getNombreProducto()
                        + (aplica
                        ? " aplica al beneficio."
                        : " no aplica al beneficio.")
        );


        // =========================================================
        // 12. BICONSUMER
        // Mostrar información de una línea y su producción
        // =========================================================

        BiConsumer<String, Integer> mostrarProduccionLinea =
                (linea, cantidad) ->
                        System.out.println(
                                "Linea: " + linea
                                        + " | Producción: "
                                        + cantidad
                        );

        Map<String, Integer> produccionPorLinea =
                registros.stream()
                        .collect(Collectors.groupingBy(
                                RegistroProducto::getLineaProduccion,
                                Collectors.summingInt(
                                        RegistroProducto::getCantidadProducto
                                )
                        ));

        System.out.println(
                "\nPRODUCCIÓN TOTAL POR LÍNEA:"
        );

        produccionPorLinea.forEach(
                mostrarProduccionLinea
        );


        // =========================================================
        // 13. CANTIDAD TOTAL PRODUCIDA
        // =========================================================

        int cantidadTotal =
                registros.stream()
                        .mapToInt(
                                RegistroProducto::getCantidadProducto
                        )
                        .sum();

        System.out.println(
                "\nCANTIDAD TOTAL PRODUCIDA: "
                        + cantidadTotal
        );


        // =========================================================
        // 14. TOTAL DE UNIDADES DEFECTUOSAS
        // =========================================================

        int totalDefectuosas =
                registros.stream()
                        .mapToInt(
                                RegistroProducto::getCantidadDefectuosa
                        )
                        .sum();

        System.out.println(
                "TOTAL DE UNIDADES DEFECTUOSAS: "
                        + totalDefectuosas
        );


        // =========================================================
        // 15. COSTO TOTAL DE PRODUCCIÓN
        // =========================================================

        double costoTotal =
                registros.stream()
                        .mapToDouble(registro -> calcularCostoTotal.apply(registro))
                        .sum();

        System.out.printf(
                "COSTO TOTAL DE PRODUCCIÓN: $%,.2f%n",
                costoTotal
        );


        // =========================================================
        // 16. PÉRDIDA ECONÓMICA TOTAL
        // =========================================================

        double perdidaTotal =
                registros.stream()
                        .mapToDouble(registro ->
                                calcularPerdida.apply(
                                        registro.getCantidadDefectuosa(),
                                        registro.getCostoUnitario()
                                )
                        )
                        .sum();

        System.out.printf(
                "PÉRDIDA ECONÓMICA TOTAL: $%,.2f%n",
                perdidaTotal
        );


        // =========================================================
        // 17. PROMEDIO DE CUMPLIMIENTO
        // =========================================================

        double promedioCumplimiento =
                registros.stream()
                        .mapToDouble(calcularCumplimiento::apply)
                        .average()
                        .orElse(0);

        System.out.printf(
                "CUMPLIMIENTO PROMEDIO: %.2f%%%n",
                promedioCumplimiento
        );


        // =========================================================
        // 18. PRODUCTO CON MAYOR PRODUCCIÓN
        // =========================================================

        RegistroProducto mayorProduccion =
                registros.stream()
                        .max(
                                java.util.Comparator.comparingInt(
                                        RegistroProducto::getCantidadProducto
                                )
                        )
                        .orElse(null);

        System.out.println(
                "\nPRODUCTO CON MAYOR PRODUCCIÓN:"
        );

        if (mayorProduccion != null) {

            System.out.println(
                    mayorProduccion.getNombreProducto()
                            + " - "
                            + mayorProduccion.getCantidadProducto()
                            + " unidades"
            );
        }


        // =========================================================
        // 19. PRODUCTO CON MENOR PRODUCCIÓN
        // =========================================================

        RegistroProducto menorProduccion =
                registros.stream()
                        .min(
                                java.util.Comparator.comparingInt(
                                        RegistroProducto::getCantidadProducto
                                )
                        )
                        .orElse(null);

        System.out.println(
                "\nPRODUCTO CON MENOR PRODUCCIÓN:"
        );

        if (menorProduccion != null) {

            System.out.println(
                    menorProduccion.getNombreProducto()
                            + " - "
                            + menorProduccion.getCantidadProducto()
                            + " unidades"
            );
        }


        // =========================================================
        // 20. PRODUCTO CON MAYOR PÉRDIDA
        // =========================================================

        RegistroProducto productoMayorPerdida =
                registros.stream()
                        .max(
                                java.util.Comparator.comparingDouble(
                                        registro ->
                                                calcularPerdida.apply(
                                                        registro.getCantidadDefectuosa(),
                                                        registro.getCostoUnitario()
                                                )
                                )
                        )
                        .orElse(null);

        System.out.println(
                "\nPRODUCTO CON MAYOR PÉRDIDA:"
        );

        if (productoMayorPerdida != null) {

            double perdida =
                    calcularPerdida.apply(
                            productoMayorPerdida.getCantidadDefectuosa(),
                            productoMayorPerdida.getCostoUnitario()
                    );

            System.out.printf(
                    "%s - $%,.2f%n",
                    productoMayorPerdida.getNombreProducto(),
                    perdida
            );
        }


        // =========================================================
        // 21. LÍNEA CON MAYOR PRODUCCIÓN
        // =========================================================

        Map.Entry<String, Integer> lineaMayorProduccion =
                produccionPorLinea.entrySet()
                        .stream()
                        .max(
                                Map.Entry.comparingByValue()
                        )
                        .orElse(null);

        System.out.println(
                "\nLÍNEA CON MAYOR CANTIDAD PRODUCIDA:"
        );

        if (lineaMayorProduccion != null) {

            System.out.println(
                    lineaMayorProduccion.getKey()
                            + " - "
                            + lineaMayorProduccion.getValue()
                            + " unidades"
            );
        }


        // =========================================================
        // 22. LÍNEAS CON BAJO CUMPLIMIENTO
        //
        // Se considera bajo cumplimiento cuando el promedio
        // de la línea es menor al 90%.
        // =========================================================

        Map<String, Double> cumplimientoPorLinea =
                registros.stream()
                        .collect(Collectors.groupingBy(
                                RegistroProducto::getLineaProduccion,
                                Collectors.averagingDouble(
                                        calcularCumplimiento::apply
                                )
                        ));

        List<String> lineasBajoCumplimiento =
                cumplimientoPorLinea.entrySet()
                        .stream()
                        .filter(entrada ->
                                entrada.getValue() < 90)
                        .map(Map.Entry::getKey)
                        .collect(Collectors.toList());

        System.out.println(
                "\nLÍNEAS CON BAJO CUMPLIMIENTO:"
        );

        if (lineasBajoCumplimiento.isEmpty()) {

            System.out.println(
                    "No existen líneas con bajo cumplimiento."
            );

        } else {

            lineasBajoCumplimiento.forEach(
                    linea ->
                            System.out.printf(
                                    "%s - %.2f%%%n",
                                    linea,
                                    cumplimientoPorLinea.get(linea)
                            )
            );
        }


        // =========================================================
        // 23. RANKING DE PRODUCTOS POR DESEMPEÑO
        // =========================================================

        System.out.println(
                "\nRANKING DE PRODUCTOS POR CUMPLIMIENTO:"
        );

        registros.stream()
                .sorted(
                        java.util.Comparator
                                .comparingDouble(
                                        calcularCumplimiento::apply
                                )
                                .reversed()
                )
                .forEach(registro ->
                        System.out.printf(
                                "%s - %.2f%%%n",
                                registro.getNombreProducto(),
                                calcularCumplimiento.apply(registro)
                        )
                );


        // =========================================================
        // 24. REDUCE
        // Acumular el costo total de producción
        // =========================================================

        double costoReduce =
                registros.stream()
                        .map(calcularCostoTotal)
                        .reduce(
                                0.0,
                                Double::sum
                        );

        System.out.printf(
                "\nCOSTO TOTAL USANDO REDUCE: $%,.2f%n",
                costoReduce
        );


        // =========================================================
        // 25. DISTINCT
        // Mostrar las líneas existentes sin repetir
        // =========================================================

        System.out.println(
                "\nLÍNEAS EXISTENTES:"
        );

        registros.stream()
                .map(RegistroProducto::getLineaProduccion)
                .distinct()
                .sorted()
                .forEach(System.out::println);


        // =========================================================
        // 26. COUNT
        // Cantidad de registros
        // =========================================================

        long cantidadRegistros =
                registros.stream()
                        .count();

        System.out.println(
                "\nCANTIDAD DE REGISTROS: "
                        + cantidadRegistros
        );


        // =========================================================
        // 27. ANYMATCH
        // Verificar si existe algún producto crítico
        // =========================================================

        boolean existeCritico =
                registros.stream()
                        .anyMatch(productoCritico);

        System.out.println(
                "¿EXISTE ALGÚN PRODUCTO CRÍTICO?: "
                        + existeCritico
        );


        // =========================================================
        // 28. ALLMATCH
        // Verificar si todos los productos cumplen la meta
        // =========================================================

        boolean todosCumplen =
                registros.stream()
                        .allMatch(registro ->
                                registro.getCantidadProducto()
                                        >= registro.getMetaProduccion()
                        );

        System.out.println(
                "¿TODOS LOS PRODUCTOS CUMPLEN LA META?: "
                        + todosCumplen
        );


        // =========================================================
        // 29. NONE MATCH
        // Verificar que no existan productos sin producción
        // =========================================================

        boolean ningunoSinProduccion =
                registros.stream()
                        .noneMatch(registro ->
                                registro.getCantidadProducto() <= 0
                        );

        System.out.println(
                "¿NINGÚN PRODUCTO TIENE PRODUCCIÓN CERO?: "
                        + ningunoSinProduccion
        );


        // =========================================================
        // 30. LIMIT
        // Mostrar los primeros 3 productos
        // =========================================================

        System.out.println(
                "\nPRIMEROS 3 PRODUCTOS:"
        );

        registros.stream()
                .limit(3)
                .forEach(registro ->
                        System.out.println(
                                registro.getNombreProducto()
                        )
                );


        // =========================================================
        // 31. SKIP
        // Saltar los primeros 2 registros
        // =========================================================

        System.out.println(
                "\nPRODUCTOS DESPUÉS DE LOS DOS PRIMEROS:"
        );

        registros.stream()
                .skip(2)
                .forEach(registro ->
                        System.out.println(
                                registro.getNombreProducto()
                        )
                );


        // =========================================================
        // 32. CLOSURE DEL TURNO
        // =========================================================

        Runnable cierreTurno = () -> {

            System.out.println(
                    "\n=============================================="
            );

            System.out.println(
                    "             CIERRE DEL TURNO"
            );

            System.out.println(
                    "=============================================="
            );

            System.out.println(
                    "Registros procesados: "
                            + registros.size()
            );

            System.out.println(
                    "Producción total: "
                            + cantidadTotal
            );

            System.out.println(
                    "Unidades defectuosas: "
                            + totalDefectuosas
            );

            System.out.printf(
                    "Costo total: $%,.2f%n",
                    costoTotal
            );

            System.out.printf(
                    "Pérdidas económicas: $%,.2f%n",
                    perdidaTotal
            );

            System.out.printf(
                    "Cumplimiento promedio: %.2f%%%n",
                    promedioCumplimiento
            );

            System.out.println(
                    "=============================================="
            );
        };

        cierreTurno.run();


        // =========================================================
        // 33. CALLABLE
        // Generar un pequeño resumen
        // =========================================================

        Callable<String> generarResumen = () -> {

            return "Resumen: "
                    + registros.size()
                    + " registros, "
                    + cantidadTotal
                    + " unidades producidas y $"
                    + String.format("%.2f", costoTotal)
                    + " invertidos.";
        };

        System.out.println(
                "\nRESUMEN GENERADO CON CALLABLE:"
        );

        System.out.println(
                generarResumen.call()
        );


        // =========================================================
        // 34. REPORTE FINAL
        // =========================================================

        System.out.println(
                "\n\n=================================================="
        );

        System.out.println(
                "       REPORTE FINAL DE PRODUCCIÓN"
        );

        System.out.println(
                "=================================================="
        );


        System.out.println(
                "\nLÍNEAS EXISTENTES:"
        );

        produccionPorLinea.keySet()
                .stream()
                .sorted()
                .forEach(linea ->
                        System.out.println("- " + linea)
                );


        System.out.println(
                "\nPRODUCCIÓN TOTAL POR LÍNEA:"
        );

        produccionPorLinea.forEach(
                mostrarProduccionLinea
        );


        System.out.println(
                "\nPRODUCTOS CRÍTICOS:"
        );

        productosCriticos.forEach(registro -> {

            double porcentaje =
                    registro.getCantidadDefectuosa()
                            * 100.0
                            / registro.getCantidadProducto();

            System.out.printf(
                    "- %s: %.2f%% de defectos%n",
                    registro.getNombreProducto(),
                    porcentaje
            );
        });


        System.out.println(
                "\nPRODUCTOS QUE SUPERARON LA META:"
        );

        productosSobreMeta.forEach(registro ->
                System.out.println(
                        "- "
                                + registro.getNombreProducto()
                                + " | Producción: "
                                + registro.getCantidadProducto()
                                + " | Meta: "
                                + registro.getMetaProduccion()
                )
        );


        System.out.println(
                "\nUNIDADES DEFECTUOSAS: "
                        + totalDefectuosas
        );


        System.out.printf(
                "COSTO TOTAL DE PRODUCCIÓN: $%,.2f%n",
                costoTotal
        );


        System.out.printf(
                "PÉRDIDAS ECONÓMICAS: $%,.2f%n",
                perdidaTotal
        );


        if (productoMayorPerdida != null) {

            double perdida =
                    calcularPerdida.apply(
                            productoMayorPerdida.getCantidadDefectuosa(),
                            productoMayorPerdida.getCostoUnitario()
                    );

            System.out.printf(
                    "PRODUCTO CON MAYOR PÉRDIDA: %s - $%,.2f%n",
                    productoMayorPerdida.getNombreProducto(),
                    perdida
            );
        }


        if (lineaMayorProduccion != null) {

            System.out.println(
                    "LÍNEA CON MAYOR PRODUCCIÓN: "
                            + lineaMayorProduccion.getKey()
                            + " - "
                            + lineaMayorProduccion.getValue()
                            + " unidades"
            );
        }


        System.out.println(
                "\nPRODUCTO DE MAYOR PRODUCCIÓN:"
        );

        if (mayorProduccion != null) {

            System.out.println(
                    mayorProduccion.getNombreProducto()
                            + " - "
                            + mayorProduccion.getCantidadProducto()
                            + " unidades"
            );
        }


        System.out.println(
                "\nPRODUCTO DE MENOR PRODUCCIÓN:"
        );

        if (menorProduccion != null) {

            System.out.println(
                    menorProduccion.getNombreProducto()
                            + " - "
                            + menorProduccion.getCantidadProducto()
                            + " unidades"
            );
        }


        System.out.printf(
                "\nCUMPLIMIENTO PROMEDIO: %.2f%%%n",
                promedioCumplimiento
        );


        System.out.println(
                "\n=================================================="
        );

        System.out.println(
                "             FIN DEL REPORTE"
        );

        System.out.println(
                "=================================================="
        );
    }
}
