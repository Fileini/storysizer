package com.fileini.storysizer.service.group.util;

/** Replicates the sizer formula from estimation-service so the group-service
 *  can compute the sizer for a group vote without a network call. */
public final class SizerCalculator {

    private static final int[] FIBONACCI = {0, 1, 2, 3, 5, 8};

    private SizerCalculator() {}

    public static int calculate(int complexity, int reach, int dimensions, int risk, int interaction) {
        int boost =
            (complexity > 1 ? 1 : 0) +
            (dimensions > 1 ? 1 : 0) +
            (interaction > 1 ? 1 : 0) +
            (reach > 1 ? 1 : 0) +
            (risk > 1 ? 1 : 0);

        return FIBONACCI[clamp(complexity)] +
               FIBONACCI[clamp(dimensions)] +
               FIBONACCI[clamp(interaction)] +
               FIBONACCI[clamp(reach)] +
               FIBONACCI[clamp(risk)] + boost;
    }

    private static int clamp(int v) {
        return Math.max(1, Math.min(5, v));
    }
}
