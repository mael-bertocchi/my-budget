import type { FastifyInstance } from 'fastify';
import stateController from 'src/modules/state/state-controller';
import type { StatePushRequest } from 'src/modules/state/state-models';
import { StateSchema } from 'src/modules/state/state-models';

/**
 * @function stateRoutes
 * @description Defines the budget-document routes (read the whole document, replace the whole document).
 */
export default function (fastify: FastifyInstance): void {
    fastify.get('/', {
        preHandler: [fastify.identity.authenticate]
    }, stateController.getState);

    fastify.put<StatePushRequest>('/', {
        preHandler: [fastify.identity.authenticate],
        schema: {
            body: StateSchema
        }
    }, stateController.putState);
}
